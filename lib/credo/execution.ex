defmodule Credo.Execution do
  @doc """
  Every run of Credo is configured via a `Execution` struct, which is created and
  manipulated via the `Credo.Execution` module.
  """

  defstruct argv:               [],
            cli_options:        nil,

            # config
            files:              nil,
            color:              true,
            checks:             nil,
            requires:           [],
            strict:             false,
            check_for_updates:  true, # checks if there is a new version of Credo

            # options, set by the command line
            min_priority:       0,
            help:               false,
            version:            false,
            verbose:            false,
            all:                false,
            format:             nil,
            only_checks:        nil,
            ignore_checks:      nil,
            crash_on_error:     true,
            mute_exit_status:   false,
            read_from_stdin:    false,

            # state, which is accessed and changed over the course of Credo's execution
            halted:             false,
            source_files_pid:   nil,
            issues_pid:         nil,
            skipped_checks:     nil,
            assigns:            %{},
            results:            %{},
            config_comment_map: %{},
            lint_attribute_map: %{} # maps filenames to @lint attributes

  @type t :: module

  @doc """
  Returns the checks that should be run for a given `exec` struct.

  Takes all checks from the `checks:` field of the exec, matches those against
  any patterns to include or exclude certain checks given via the command line.
  """
  def checks(%__MODULE__{checks: checks, only_checks: only_checks, ignore_checks: ignore_checks}) do
    match_regexes =
      only_checks
      |> List.wrap
      |> to_match_regexes

    ignore_regexes =
      ignore_checks
      |> List.wrap
      |> to_match_regexes

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

    Enum.any?(regexes, &Regex.run(&1, check_name))
  end

  defp to_match_regexes(list) do
    Enum.map(list, fn(match_check) ->
      {:ok, match_pattern} = Regex.compile(match_check, "i")
      match_pattern
    end)
  end

  @doc """
  Sets the exec values which `strict` implies (if applicable).
  """
  def set_strict(%__MODULE__{strict: true} = exec) do
    %__MODULE__{exec | all: true, min_priority: -99}
  end
  def set_strict(%__MODULE__{strict: false} = exec) do
    %__MODULE__{exec | min_priority: 0}
  end
  def set_strict(exec), do: exec



  @doc """
  Returns the name of the command, which should be run by the given execution.
  """
  def get_command_name(exec) do
    exec.cli_options.command
  end

  def get_path(exec) do
    exec.cli_options.path
  end

  # Assigns

  def get_assign(exec, name, default \\ nil) do
    Map.get(exec.assigns, name, default)
  end

  def put_assign(exec, name, value) do
    %__MODULE__{exec | assigns: Map.put(exec.assigns, name, value)}
  end

  # Source Files

  def get_source_files(exec) do
    Credo.Execution.SourceFiles.get(exec)
  end

  def put_source_files(exec, source_files) do
    Credo.Execution.SourceFiles.put(exec, source_files)

    exec
  end

  # Issues

  def get_issues(exec) do
    exec
    |> Credo.Execution.Issues.to_map
    |> Map.values
    |> List.flatten
  end
  def get_issues(exec, filename) do
    exec
    |> Credo.Execution.Issues.to_map
    |> Map.get(filename, [])
  end

  # Results

  def get_result(exec, name, default \\ nil) do
    Map.get(exec.results, name, default)
  end

  def put_result(exec, name, value) do
    %__MODULE__{exec | results: Map.put(exec.results, name, value)}
  end

  # Halt


  def halt(exec) do
    %__MODULE__{exec | halted: true}
  end

end
