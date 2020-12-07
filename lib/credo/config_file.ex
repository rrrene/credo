defmodule Credo.ConfigFile do
  @doc """
  `ConfigFile` structs represent all loaded and merged config files in a run.
  """

  @config_filename ".credo.exs"
  @default_config_name "default"
  @origin_user :file

  @default_glob "**/*.{ex,exs}"
  @default_files_included [@default_glob]
  @default_files_excluded []
  @default_parse_timeout 5000
  @default_strict false
  @default_color true

  alias Credo.Execution

  defstruct origin: nil,
            filename: nil,
            config_name_found?: nil,
            files: nil,
            color: true,
            checks: nil,
            requires: [],
            plugins: [],
            parse_timeout: nil,
            strict: false

  @doc """
  Returns Execution struct representing a consolidated Execution for all `.credo.exs`
  files in `relevant_directories/1` merged into the default configuration.

  - `config_name`: name of the configuration to load
  - `safe`: if +true+, the config files are loaded using static analysis rather
            than `Code.eval_string/1`
  """
  def read_or_default(exec, dir, config_name \\ nil, safe \\ false) do
    dir
    |> relevant_config_files
    |> combine_configs(exec, dir, config_name, safe)
  end

  @doc """
  Returns the provided config_file merged into the default configuration.

  - `config_file`: full path to the custom configuration file
  - `config_name`: name of the configuration to load
  - `safe`: if +true+, the config files are loaded using static analysis rather
            than `Code.eval_string/1`
  """
  def read_from_file_path(exec, dir, config_filename, config_name \\ nil, safe \\ false) do
    if File.exists?(config_filename) do
      combine_configs([config_filename], exec, dir, config_name, safe)
    else
      {:error, {:notfound, "Given config file does not exist: #{config_filename}"}}
    end
  end

  defp combine_configs(files, exec, dir, config_name, safe) do
    config_files =
      files
      |> Enum.filter(&File.exists?/1)
      |> Enum.map(&{@origin_user, &1, File.read!(&1)})

    exec = Enum.reduce(config_files, exec, &Execution.append_config_file(&2, &1))

    Execution.get_config_files(exec)
    |> Enum.map(&from_exs(dir, config_name || @default_config_name, &1, safe))
    |> ensure_any_config_found(config_name)
    |> merge()
    |> add_given_directory_to_files(dir)
    |> ensure_values_present()
  end

  defp ensure_any_config_found(list, config_name) do
    config_not_found =
      Enum.all?(list, fn
        {:ok, %__MODULE__{config_name_found?: false}} -> true
        _ -> false
      end)

    if config_not_found do
      filenames_as_list =
        list
        |> Enum.map(fn
          {:ok, %__MODULE__{origin: :file, filename: filename}} -> "  * #{filename}\n"
          _ -> nil
        end)
        |> Enum.reject(&is_nil/1)

      message =
        case filenames_as_list do
          [] ->
            "Given config name #{inspect(config_name)} does not exist."

          filenames_as_list ->
            """
            Given config name #{inspect(config_name)} does not exist in any config file:

            #{filenames_as_list}
            """
        end
        |> String.trim()

      {:error, {:config_name_not_found, message}}
    else
      list
    end
  end

  defp relevant_config_files(dir) do
    dir
    |> relevant_directories
    |> add_config_files
  end

  @doc """
  Returns all parent directories of the given `dir` as well as each `./config`
  sub-directory.
  """
  def relevant_directories(dir) do
    dir
    |> Path.expand()
    |> Path.split()
    |> Enum.reverse()
    |> get_dir_paths
    |> add_config_dirs
  end

  defp ensure_values_present({:ok, config}) do
    # TODO: config.check_for_updates is deprecated, but should not lead to a validation error
    config = %__MODULE__{
      origin: config.origin,
      filename: config.filename,
      config_name_found?: config.config_name_found?,
      checks: config.checks,
      color: merge_boolean(@default_color, config.color),
      files: %{
        included: merge_files_default(@default_files_included, config.files.included),
        excluded: merge_files_default(@default_files_excluded, config.files.excluded)
      },
      parse_timeout: merge_parse_timeout(@default_parse_timeout, config.parse_timeout),
      plugins: config.plugins || [],
      requires: config.requires || [],
      strict: merge_boolean(@default_strict, config.strict)
    }

    {:ok, config}
  end

  defp ensure_values_present(error), do: error

  defp get_dir_paths(dirs), do: do_get_dir_paths(dirs, [])

  defp do_get_dir_paths(dirs, acc) when length(dirs) < 2, do: acc

  defp do_get_dir_paths([dir | tail], acc) do
    expanded_path =
      tail
      |> Enum.reverse()
      |> Path.join()
      |> Path.join(dir)

    do_get_dir_paths(tail, [expanded_path | acc])
  end

  defp add_config_dirs(paths) do
    Enum.flat_map(paths, fn path -> [path, Path.join(path, "config")] end)
  end

  defp add_config_files(paths) do
    for path <- paths, do: Path.join(path, @config_filename)
  end

  defp from_exs(dir, config_name, {origin, filename, exs_string}, safe) do
    case Credo.ExsLoader.parse(exs_string, safe) do
      {:ok, data} ->
        from_data(data, dir, filename, origin, config_name)

      {:error, {line_no, description, trigger}} ->
        {:error, {:badconfig, filename, line_no, description, trigger}}

      {:error, reason} ->
        {:error, {:badconfig, filename, reason}}
    end
  end

  defp from_data(data, dir, filename, origin, config_name) do
    data =
      data[:configs]
      |> List.wrap()
      |> Enum.find(&(&1[:name] == config_name))

    config_name_found? = not is_nil(data)

    config_file = %__MODULE__{
      origin: origin,
      filename: filename,
      config_name_found?: config_name_found?,
      checks: checks_from_data(data),
      color: data[:color],
      files: files_from_data(data, dir),
      parse_timeout: data[:parse_timeout],
      plugins: data[:plugins] || [],
      requires: data[:requires] || [],
      strict: data[:strict]
    }

    {:ok, config_file}
  end

  defp files_from_data(data, dir) do
    case data[:files] do
      nil ->
        nil

      %{} = files ->
        included_files = files[:included] || dir

        included_dir =
          included_files
          |> List.wrap()
          |> Enum.map(&join_default_files_if_directory/1)

        %{
          included: included_dir,
          excluded: files[:excluded] || @default_files_excluded
        }
    end
  end

  defp checks_from_data(data) do
    case data[:checks] do
      checks when is_list(checks) ->
        checks

      _ ->
        []
    end
  end

  @doc """
  Merges the given structs from left to right, meaning that later entries
  overwrites earlier ones.

      merge(base, other)

  Any options in `other` will overwrite those in `base`.

  The `files:` field is merged, meaning that you can define `included` and/or
  `excluded` and only override the given one.

  The `checks:` field is merged.
  """
  def merge(list) when is_list(list) do
    base = List.first(list)
    tail = List.delete_at(list, 0)

    merge(tail, base)
  end

  # bubble up errors from parsing the config so we can deal with them at the top-level
  def merge({:error, _} = error), do: error

  def merge([], config), do: config

  def merge([other | tail], base) do
    new_base = merge(base, other)

    merge(tail, new_base)
  end

  # bubble up errors from parsing the config so we can deal with them at the top-level
  def merge({:error, _} = a, _), do: a
  def merge(_, {:error, _} = a), do: a

  def merge({:ok, base}, {:ok, other}) do
    config_file = %__MODULE__{
      checks: merge_checks(base, other),
      color: merge_boolean(base.color, other.color),
      files: merge_files(base, other),
      parse_timeout: merge_parse_timeout(base.parse_timeout, other.parse_timeout),
      plugins: base.plugins ++ other.plugins,
      requires: base.requires ++ other.requires,
      strict: merge_boolean(base.strict, other.strict)
    }

    {:ok, config_file}
  end

  defp merge_boolean(base, other)

  defp merge_boolean(_base, true), do: true
  defp merge_boolean(_base, false), do: false
  defp merge_boolean(base, _), do: base

  defp merge_files_default(_base, [_head | _tail] = non_empty_list), do: non_empty_list
  defp merge_files_default(base, _), do: base

  defp merge_parse_timeout(_base, timeout) when is_integer(timeout), do: timeout
  defp merge_parse_timeout(base, _), do: base

  def merge_checks(%__MODULE__{checks: checks_base}, %__MODULE__{checks: checks_other}) do
    base = normalize_check_tuples(checks_base)
    other = normalize_check_tuples(checks_other)

    Keyword.merge(base, other)
  end

  def merge_files(%__MODULE__{files: files_base}, %__MODULE__{files: files_other}) do
    %{
      included: files_other[:included] || files_base[:included],
      excluded: files_other[:excluded] || files_base[:excluded]
    }
  end

  defp normalize_check_tuples(nil), do: []

  defp normalize_check_tuples(list) when is_list(list) do
    Enum.map(list, &normalize_check_tuple/1)
  end

  defp normalize_check_tuple({name}), do: {name, []}
  defp normalize_check_tuple(tuple), do: tuple

  defp join_default_files_if_directory(dir) do
    if File.dir?(dir) do
      Path.join(dir, @default_files_included)
    else
      dir
    end
  end

  defp add_given_directory_to_files({:error, _} = error, _dir) do
    error
  end

  defp add_given_directory_to_files({:ok, %__MODULE__{files: files} = config}, dir) do
    files = %{
      included:
        files[:included]
        |> List.wrap()
        |> Enum.map(&add_directory_to_file(&1, dir))
        |> Enum.uniq(),
      excluded:
        files[:excluded]
        |> List.wrap()
        |> Enum.map(&add_directory_to_file(&1, dir))
        |> Enum.uniq()
    }

    {:ok, %__MODULE__{config | files: files}}
  end

  defp add_directory_to_file(file_or_glob, dir) when is_binary(file_or_glob) do
    if File.dir?(dir) do
      if dir == "." || file_or_glob =~ ~r/^\// do
        file_or_glob
      else
        Path.join(dir, file_or_glob)
      end
    else
      dir
    end
  end

  defp add_directory_to_file(regex, _), do: regex
end
