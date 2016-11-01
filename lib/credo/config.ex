defmodule Credo.Config do
  @doc """
  Every run of Credo is configured via a `Config` object, which is created and
  manipulated via the `Credo.Config` module.
  """

  defstruct files:              nil,
            checks:             nil,
            requires:           [],
            min_priority:       0,
            help:               false,
            version:            false,
            verbose:            false,
            strict:             false,
            all:                false,
            format:             nil,
            match_checks:       nil,
            ignore_checks:      nil,
            crash_on_error:     true,
            check_for_updates:  true, # checks if there is a new version of Credo
            read_from_stdin:    false,
            lint_attribute_map:   %{} # maps filenames to @lint attributes

  @config_filename ".credo.exs"
  @default_config_name "default"
  @default_config_file File.read!(@config_filename)

  @default_glob "**/*.{ex,exs}"
  @default_files_included [@default_glob]
  @default_files_excluded []

  @doc """
  Returns the checks that should be run for a given `config` object.

  Takes all checks from the `checks:` field of the config, matches those against
  any patterns to include or exclude certain checks given via the command line.
  """
  def checks(%__MODULE__{checks: checks, match_checks: match_checks, ignore_checks: ignore_checks}) do
    match_regexes = match_checks |> List.wrap |> to_match_regexes
    ignore_regexes = ignore_checks |> List.wrap |> to_match_regexes

    checks
    |> Enum.filter(&match_regex(&1, match_regexes, true))
    |> Enum.reject(&match_regex(&1, ignore_regexes, false))
  end

  defp match_regex(_tuple, [], default_for_empty), do: default_for_empty
  defp match_regex(tuple, regexes, _default_for_empty) do
    check_name =
      tuple
      |> Tuple.to_list
      |> List.first
      |> to_string

    regexes
    |> Enum.any?(&Regex.run(&1, check_name))
  end

  defp to_match_regexes(list) do
    list
    |> Enum.map(fn(match_check) ->
        {:ok, match_pattern} = Regex.compile(match_check, "i")
        match_pattern
      end)
  end

  @doc """
  Returns Config struct representing a consolidated Config for all `.credo.exs`
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
    |> set_strict()
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
    expanded_path = tail |> Enum.reverse |> Path.join |> Path.join(dir)
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
      strict: data[:strict] || false
    }
  end

  defp files_from_data(data, dir) do
    files = data[:files] || %{}
    included_dir =
      (files[:included] || dir)
      |> List.wrap
      |> Enum.map(&join_default_files_if_directory/1)

    %{
      included: included_dir,
      excluded: files[:excluded] || @default_files_excluded,
    }
  end

  defp checks_from_data(data) do
    case data[:checks] do
      checks when is_list(checks) -> checks
      _ -> []
    end
  end

  @doc """
  Merges the given Config objects from left to right, meaning that later entries
  overwrites earlier ones.

      merge(base, other)

  Any options in `other` will overwrite those in `base`.

  The `files:` field is merged, meaning that you can define `included` and/or
  `excluded` and only override the given one.

  The `checks:` field is merged.
  """
  def merge(list) when is_list(list) do
    base = list |> List.first
    tail = list |> List.delete_at(0)
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
    list
    |> Enum.map(&normalize_check_tuple/1)
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
      if dir == "." do
        file_or_glob
      else
        Path.join(dir, file_or_glob)
      end
    else
      dir
    end
  end
  defp add_directory_to_file(regex, _), do: regex

  @doc """
  Sets the config values which `strict` implies (if applicable).
  """
  def set_strict(%__MODULE__{strict: true} = config) do
    %__MODULE__{config | all: true, min_priority: -99}
  end
  def set_strict(config), do: config
end
