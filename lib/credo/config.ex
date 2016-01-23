defmodule Credo.Config do
  @doc """
  Every run of Credo is configured via a `Config` object, which is created and
  manipulated via the `Credo.Config` module.
  """

  defstruct files:          nil,
            checks:         nil,
            min_priority:   0,
            help:           false,
            version:        false,
            verbose:        false,
            all:            false,
            one_line:       false, # rename to one-line
            match_checks:   nil,
            ignore_checks:  nil,
            crash_on_error: true

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

  def read_or_default(dir, config_name \\ nil) do
    dir
    |> relevant_config_files
    |> Enum.filter(&File.exists?/1)
    |> Enum.map(&File.read!/1)
    |> List.insert_at(0, @default_config_file)
    |> Enum.map(&from_exs(dir, config_name || @default_config_name, &1))
    |> merge
    |> add_given_directory_to_files(dir)
  end

  defp relevant_config_files(dir) do
    dir
    |> relevant_directories
    |> add_config_files
  end

  defp relevant_directories(dir) do
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

  defp from_exs(dir, config_name, exs_string) do
    exs_string
    |> Credo.ExsLoader.parse
    |> from_data(dir, config_name)
  end

  defp from_data(data, dir, config_name) do
    data =
      data[:configs]
      |> List.wrap
      |> Enum.find(&(&1[:name] == config_name))

    %__MODULE__{
      files: files_from_data(data, dir),
      checks: checks_from_data(data)
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

  The `checks:` field is overwritten in full, meaning that there is no
  "blending" of checks from one Config to another. If you are including this
  field in a Config, it basically means "I want to run these checks and
  these checks only".
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
      files: merge_files(base, other),
      checks: merge_checks(base, other),
    }
  end
  def merge_checks(%__MODULE__{checks: checks_base}, %__MODULE__{checks: checks_other}) do
    checks_other || checks_base
  end
  def merge_files(%__MODULE__{files: files_base}, %__MODULE__{files: files_other}) do
    %{
      included: files_other[:included] || files_base[:included],
      excluded: files_other[:excluded] || files_base[:excluded],
    }
  end

  defp join_default_files_if_directory(dir) do
    if File.dir?(dir) do
      Path.join(dir, @default_files_included)
    else
      dir
    end
  end

  defp add_given_directory_to_files(%__MODULE__{files: files} = config, dir) do
    files = %{
      included: files[:included] |> Enum.map(&add_directory_to_file(&1, dir)),
      excluded: files[:excluded] |> Enum.map(&add_directory_to_file(&1, dir))
    }
    %__MODULE__{config | files: files}
  end

  defp add_directory_to_file(file_or_glob, dir) do
    if File.dir?(dir) do
      Path.join(dir, file_or_glob)
    else
      dir
    end
  end
end
