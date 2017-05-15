defmodule Credo.ConfigFile do
  @doc """
  `ConfigFile` structs represent all loaded and merged config files in a run.
  """

  defstruct files:              nil,
            color:              true,
            checks:             nil,
            requires:           [],
            strict:             false,
            check_for_updates:  true  # checks if there is a new version of Credo

  @config_filename ".credo.exs"
  @default_config_name "default"
  @default_config_file File.read!(@config_filename)

  @default_glob "**/*.{ex,exs}"
  @default_files_included [@default_glob]
  @default_files_excluded []

  @doc """
  Returns Execution struct representing a consolidated Execution for all `.credo.exs`
  files in `relevant_directories/1` merged into the default configuration.

  - `config_name`: name of the configuration to load
  - `safe`: if +true+, the config files are loaded using static analysis rather
            than `Code.eval_string/1`
  """
  def read_or_default(dir, config_name \\ nil, safe \\ false) do
    dir
    |> relevant_config_files
    |> Enum.filter(&File.exists?/1)
    |> Enum.map(&File.read!/1)
    |> List.insert_at(0, @default_config_file)
    |> Enum.map(&from_exs(dir, config_name || @default_config_name, &1, safe))
    |> merge
    |> add_given_directory_to_files(dir)
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
    |> Path.expand
    |> Path.split
    |> Enum.reverse
    |> get_dir_paths
    |> add_config_dirs
  end

  defp get_dir_paths(dirs), do: do_get_dir_paths(dirs, [])

  defp do_get_dir_paths(dirs, acc) when length(dirs) < 2, do: acc
  defp do_get_dir_paths([dir | tail], acc) do
    expanded_path =
      tail
      |> Enum.reverse
      |> Path.join
      |> Path.join(dir)

    do_get_dir_paths(tail, [expanded_path | acc])
  end

  defp add_config_dirs(paths) do
    Enum.flat_map(paths, fn(path) -> [path, Path.join(path, "config")] end)
  end

  defp add_config_files(paths) do
    for path <- paths, do: Path.join(path, @config_filename)
  end

  defp from_exs(dir, config_name, exs_string, safe) do
    exs_string
    |> Credo.ExsLoader.parse(safe)
    |> from_data(dir, config_name)
  end

  defp from_data(data, dir, config_name) do
    data =
      data[:configs]
      |> List.wrap
      |> Enum.find(&(&1[:name] == config_name))

    %__MODULE__{
      check_for_updates: data[:check_for_updates] || false,
      requires: data[:requires] || [],
      files: files_from_data(data, dir),
      checks: checks_from_data(data),
      strict: data[:strict] || false,
      color: data[:color] || false
    }
  end

  defp files_from_data(data, dir) do
    files = data[:files] || %{}
    included_files = files[:included] || dir

    included_dir =
      included_files
      |> List.wrap
      |> Enum.map(&join_default_files_if_directory/1)

    %{
      included: included_dir,
      excluded: files[:excluded] || @default_files_excluded,
    }
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
  def merge([], config), do: config
  def merge([other|tail], base) do
    new_base = merge(base, other)
    merge(tail, new_base)
  end
  def merge(base, other) do
    %__MODULE__{
      check_for_updates: other.check_for_updates,
      requires: base.requires ++ other.requires,
      files: merge_files(base, other),
      checks: merge_checks(base, other),
      strict: other.strict,
      color: other.color,
    }
  end
  def merge_checks(%__MODULE__{checks: checks_base}, %__MODULE__{checks: checks_other}) do
    base = normalize_check_tuples(checks_base)
    other = normalize_check_tuples(checks_other)
    Keyword.merge(base, other)
  end
  def merge_files(%__MODULE__{files: files_base}, %__MODULE__{files: files_other}) do
    %{
      included: files_other[:included] || files_base[:included],
      excluded: files_other[:excluded] || files_base[:excluded],
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

  defp add_given_directory_to_files(%__MODULE__{files: files} = config, dir) do
    files = %{
      included:
        files[:included]
        |> Enum.map(&add_directory_to_file(&1, dir))
        |> Enum.uniq,
      excluded:
        files[:excluded]
        |> Enum.map(&add_directory_to_file(&1, dir))
        |> Enum.uniq
    }

    %__MODULE__{config | files: files}
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
