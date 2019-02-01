defmodule Credo.Execution do
  @moduledoc """
  Every run of Credo is configured via a `Execution` struct, which is created and
  manipulated via the `Credo.Execution` module.
  """

  @doc """
  The `Execution` struct is created and manipulated via the `Credo.Execution` module.
  """
  defstruct argv: [],
            cli_options: nil,

            # config
            files: nil,
            color: true,
            debug: false,
            checks: nil,
            requires: [],
            plugin_modules: [],
            strict: false,

            # checks if there is a new version of Credo
            check_for_updates: true,

            # options, set by the command line
            min_priority: 0,
            help: false,
            version: false,
            verbose: false,
            all: false,
            format: nil,
            only_checks: nil,
            ignore_checks: nil,
            crash_on_error: true,
            mute_exit_status: false,
            read_from_stdin: false,

            # state, which is accessed and changed over the course of Credo's execution
            process: [
              parse_cli_options: [
                {Credo.Execution.Task.ParseOptions, []}
              ],
              validate_cli_options: [
                {Credo.Execution.Task.ValidateOptions, []}
              ],
              convert_cli_options_to_config: [
                {Credo.Execution.Task.ConvertCLIOptionsToConfig, []}
              ],
              start_plugin_modules: [
                {Credo.Execution.Task.InitializePlugins, []}
              ],
              determine_command: [
                {Credo.Execution.Task.DetermineCommand, []}
              ],
              set_default_command: [
                {Credo.Execution.Task.SetDefaultCommand, []}
              ],
              resolve_config: [
                {Credo.Execution.Task.UseColors, []},
                {Credo.Execution.Task.RequireRequires, []}
              ],
              validate_config: [
                {Credo.Execution.Task.ValidateConfig, []}
              ],
              run_command: [
                {Credo.Execution.Task.RunCommand, []}
              ],
              halt_execution: [
                {Credo.Execution.Task.AssignExitStatusForIssues, []}
              ]
            ],
            commands: %{
              "categories" => Credo.CLI.Command.Categories.CategoriesCommand,
              "explain" => Credo.CLI.Command.Explain.ExplainCommand,
              "gen.check" => Credo.CLI.Command.GenCheck,
              "gen.config" => Credo.CLI.Command.GenConfig,
              "help" => Credo.CLI.Command.Help,
              "info" => Credo.CLI.Command.Info.InfoCommand,
              "list" => Credo.CLI.Command.List.ListCommand,
              "suggest" => Credo.CLI.Command.Suggest.SuggestCommand,
              "version" => Credo.CLI.Command.Version
            },
            current_task: nil,
            parent_task: nil,
            halted: false,
            source_files_pid: nil,
            issues_pid: nil,
            timing_pid: nil,
            skipped_checks: nil,
            assigns: %{},
            results: %{},
            config_comment_map: %{}

  @type t :: module

  alias Credo.Execution.ExecutionIssues
  alias Credo.Execution.ExecutionSourceFiles
  alias Credo.Execution.ExecutionTiming

  @doc "Builds an Execution struct for the the given `argv`."
  def build(argv) when is_list(argv) do
    %__MODULE__{argv: argv}
  end

  @doc """
  Returns the checks that should be run for a given `exec` struct.

  Takes all checks from the `checks:` field of the exec, matches those against
  any patterns to include or exclude certain checks given via the command line.
  """
  def checks(exec)

  def checks(%__MODULE__{checks: checks, only_checks: only_checks, ignore_checks: ignore_checks}) do
    only_matching = filter_only_checks(checks, only_checks)
    ignore_matching = filter_ignore_checks(checks, ignore_checks)
    result = only_matching -- ignore_matching

    {result, only_matching, ignore_matching}
  end

  defp filter_only_checks(checks, nil), do: checks
  defp filter_only_checks(checks, []), do: checks
  defp filter_only_checks(checks, patterns), do: filter_checks(checks, patterns)

  defp filter_ignore_checks(_checks, nil), do: []
  defp filter_ignore_checks(_checks, []), do: []
  defp filter_ignore_checks(checks, patterns), do: filter_checks(checks, patterns)

  defp filter_checks(checks, patterns) do
    regexes =
      patterns
      |> List.wrap()
      |> to_match_regexes

    Enum.filter(checks, &match_regex(&1, regexes, true))
  end

  defp match_regex(_tuple, [], default_for_empty), do: default_for_empty

  defp match_regex(tuple, regexes, _default_for_empty) do
    check_name =
      tuple
      |> Tuple.to_list()
      |> List.first()
      |> to_string

    Enum.any?(regexes, &Regex.run(&1, check_name))
  end

  defp to_match_regexes(list) do
    Enum.map(list, fn match_check ->
      {:ok, match_pattern} = Regex.compile(match_check, "i")
      match_pattern
    end)
  end

  @doc """
  Sets the exec values which `strict` implies (if applicable).
  """
  def set_strict(exec)

  def set_strict(%__MODULE__{strict: true} = exec) do
    %__MODULE__{exec | all: true, min_priority: -99}
  end

  def set_strict(%__MODULE__{strict: false} = exec) do
    %__MODULE__{exec | min_priority: 0}
  end

  def set_strict(exec), do: exec

  @doc false
  def get_path(exec) do
    exec.cli_options.path
  end

  # Commands

  @doc "Returns the name of the command, which should be run by the given execution."
  def get_command_name(exec) do
    exec.cli_options.command
  end

  @doc "Returns all valid command names."
  def get_valid_command_names(exec) do
    Map.keys(exec.commands)
  end

  def get_command(exec, name) do
    Map.get(exec.commands, name)
  end

  @doc "Puts the given `command_mod` with the given `name` as command into the given `exec` struct."
  def put_command(exec, name, command_mod) do
    %__MODULE__{exec | commands: Map.put(exec.commands, name, command_mod)}
  end

  # Assigns

  @doc "Returns the assign with the given `name` for the given `exec` struct (or return the given `default` value)."
  def get_assign(exec, name, default \\ nil) do
    Map.get(exec.assigns, name, default)
  end

  @doc "Puts the given `value` with the given `name` as assign into the given `exec` struct."
  def put_assign(exec, name, value) do
    %__MODULE__{exec | assigns: Map.put(exec.assigns, name, value)}
  end

  # Source Files

  @doc "Returns all source files for the given `exec` struct."
  def get_source_files(exec) do
    Credo.Execution.ExecutionSourceFiles.get(exec)
  end

  @doc "Puts the given `source_files` into the given `exec` struct."
  def put_source_files(exec, source_files) do
    ExecutionSourceFiles.put(exec, source_files)

    exec
  end

  # Issues

  @doc "Returns all issues for the given `exec` struct."
  def get_issues(exec) do
    exec
    |> ExecutionIssues.to_map()
    |> Map.values()
    |> List.flatten()
  end

  @doc "Returns issues for the given `exec` struct that relate to the given `filename`."
  def get_issues(exec, filename) do
    exec
    |> ExecutionIssues.to_map()
    |> Map.get(filename, [])
  end

  @doc "Sets the issues in the given `exec` struct."
  def set_issues(exec, issues) do
    ExecutionIssues.set(exec, issues)

    exec
  end

  # Results

  @doc "Returns the result with the given `name` for the given `exec` struct (or return the given `default` value)."
  def get_result(exec, name, default \\ nil) do
    Map.get(exec.results, name, default)
  end

  @doc "Puts the given `value` with the given `name` as result into the given `exec` struct."
  def put_result(exec, name, value) do
    %__MODULE__{exec | results: Map.put(exec.results, name, value)}
  end

  # Halt

  @doc "Halts further execution of the process."
  def halt(exec) do
    %__MODULE__{exec | halted: true}
  end

  @doc false
  def start_servers(%__MODULE__{} = exec) do
    exec
    |> ExecutionSourceFiles.start_server()
    |> ExecutionIssues.start_server()
    |> ExecutionTiming.start_server()
  end

  # Task tracking

  @doc false
  def set_parent_and_current_task(exec, parent_task, current_task) do
    %__MODULE__{exec | parent_task: parent_task, current_task: current_task}
  end

  # Running tasks

  @doc false
  def run(initial_exec, process_name) do
    process_list = Map.get(initial_exec, process_name)

    Enum.reduce(process_list, initial_exec, fn {_name, list}, outer_exec ->
      Enum.reduce(list, outer_exec, fn {task, opts}, exec ->
        Credo.Execution.Task.run(task, exec, opts)
      end)
    end)
  end

  @doc false
  def prepend_task(exec, group_name, task_mod) when is_atom(task_mod) do
    prepend_task(exec, group_name, {task_mod, []})
  end

  def prepend_task(exec, group_name, task_tuple) do
    process =
      Enum.map(exec.process, fn
        {^group_name, list} -> {group_name, [task_tuple] ++ list}
        value -> value
      end)

    %__MODULE__{exec | process: process}
  end

  @doc false
  def append_task(exec, group_name, task_mod) when is_atom(task_mod) do
    append_task(exec, group_name, {task_mod, []})
  end

  def append_task(exec, group_name, task_tuple) do
    process =
      Enum.map(exec.process, fn
        {^group_name, list} -> {group_name, list ++ [task_tuple]}
        value -> value
      end)

    %__MODULE__{exec | process: process}
  end
end
