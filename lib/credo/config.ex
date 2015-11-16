defmodule Credo.Config do
  defstruct files:        nil,
            checks:       nil,
            min_priority: 0,
            help:         false,
            version:      false,
            verbose:      false,
            all:          false,
            one_line:        false, # rename to one-line
            match_checks:   nil,
            ignore_checks:   nil,
            crash_on_error: true

  @config_filename ".credo.exs"
  @default_config_name "default"
  @default_config_file """
# This file contains the configuration for Credo.
# If you find anything wrong or unclear in this file, please report an
# issue on GitHub: https://github.com/rrrene/credo/issues
%{
  # You can have as many configs as you like under the "configs" key.
  configs: [
    %{
      #
      # names are arbitrary, default is "default"
      # run any config using the "-C" switch
      name: "default",
      #
      # these are the files included in the analysis
      files: %{
        #
        # you can give explicit globs or simply directories
        # in the latter case `**/*.{ex,exs}` will be used
        included: ["lib/", "src/", "web/"],
        excluded: []
      },
      #
      # all these checks are run
      # you can include configuration as the second element of the tuple
      #
      # there are two ways of deactivating a check:
      # 1. deleting the check from this list
      # 2. putting `false` as second element (to quickly "comment it out")
      #
      checks: [
        {Credo.Check.Consistency.ExceptionNames},
        {Credo.Check.Consistency.LineEndings},
        {Credo.Check.Consistency.TabsOrSpaces},

        {Credo.Check.Design.AliasUsage},
        {Credo.Check.Design.DuplicatedCode},
        {Credo.Check.Design.TagFIXME},
        {Credo.Check.Design.TagTODO},

        {Credo.Check.Readability.FunctionNames},
        {Credo.Check.Readability.MaxLineLength},
        {Credo.Check.Readability.ModuleAttributeNames},
        {Credo.Check.Readability.ModuleNames},
        {Credo.Check.Readability.PredicateFunctionNames},
        {Credo.Check.Readability.TrailingBlankLine},
        {Credo.Check.Readability.TrailingWhiteSpace},
        {Credo.Check.Readability.VariableNames},

        {Credo.Check.Refactor.ABCSize},
        {Credo.Check.Refactor.CyclomaticComplexity},
        {Credo.Check.Refactor.NegatedConditionsInUnless},
        {Credo.Check.Refactor.NegatedConditionsWithElse},
        {Credo.Check.Refactor.Nesting},
        {Credo.Check.Refactor.UnlessWithElse},

        {Credo.Check.Warning.IExPry},
        {Credo.Check.Warning.IoInspect},
        {Credo.Check.Warning.NameRedeclarationByAssignment},
        {Credo.Check.Warning.NameRedeclarationByCase},
        {Credo.Check.Warning.NameRedeclarationByDef},
        {Credo.Check.Warning.NameRedeclarationByFn},
        {Credo.Check.Warning.OperationOnSameValues},
        {Credo.Check.Warning.UnusedStringOperation},
      ]
    }
  ]
}
  """

  @default_glob "**/*.{ex,exs}"
  @default_files_included [@default_glob]
  @default_files_excluded []

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

  def to_match_regexes(list) do
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
    path = dir |> Path.expand |> Path.join("config")
    count = path |> Path.split |> Enum.count
    Enum.reduce(0..count-2, [], fn(i, acc) ->
      new_path =
        path
        |> Path.join(String.duplicate("../", i))
        |> Path.expand
        |> Path.join(@config_filename)

      [new_path | acc]
    end)
  end

  def from_exs(dir, config_name, exs_string \\ "%{}") do
    exs_string
    |> Credo.ExsLoader.parse
    |> from_data(dir, config_name)
  end

  def from_data(data, dir, config_name) do
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
