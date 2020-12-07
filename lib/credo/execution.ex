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
            cli_switches: [
              all_priorities: :boolean,
              all: :boolean,
              files_included: :keep,
              files_excluded: :keep,
              checks_with_tag: :keep,
              checks_without_tag: :keep,
              checks: :string,
              config_name: :string,
              config_file: :string,
              color: :boolean,
              crash_on_error: :boolean,
              debug: :boolean,
              enable_disabled_checks: :string,
              mute_exit_status: :boolean,
              format: :string,
              help: :boolean,
              ignore_checks: :string,
              ignore: :string,
              min_priority: :string,
              only: :string,
              read_from_stdin: :boolean,
              strict: :boolean,
              verbose: :boolean,
              version: :boolean,
              watch: :boolean
            ],
            cli_aliases: [
              a: :all,
              A: :all_priorities,
              c: :checks,
              C: :config_name,
              d: :debug,
              h: :help,
              i: :ignore_checks,
              v: :version
            ],
            cli_switch_plugin_param_converters: [],

            # config
            files: nil,
            color: true,
            debug: false,
            checks: nil,
            requires: [],
            plugins: [],
            parse_timeout: 5000,
            strict: false,

            # options, set by the command line
            all: false,
            crash_on_error: true,
            enable_disabled_checks: nil,
            format: nil,
            help: false,
            ignore_checks_tags: [],
            ignore_checks: nil,
            max_concurrent_check_runs: nil,
            min_priority: 0,
            mute_exit_status: false,
            only_checks_tags: [],
            only_checks: nil,
            read_from_stdin: false,
            verbose: false,
            version: false,

            # state, which is accessed and changed over the course of Credo's execution
            pipeline_map: %{},
            commands: %{},
            config_files: [],
            current_task: nil,
            parent_task: nil,
            initializing_plugin: nil,
            halted: false,
            config_files_pid: nil,
            source_files_pid: nil,
            issues_pid: nil,
            timing_pid: nil,
            skipped_checks: nil,
            assigns: %{},
            results: %{},
            config_comment_map: %{}

  @type t :: %__MODULE__{}

  @execution_pipeline_key __MODULE__
  @execution_pipeline [
    __pre__: [
      {Credo.Execution.Task.AppendDefaultConfig, []},
      {Credo.Execution.Task.ParseOptions, []},
      {Credo.Execution.Task.ConvertCLIOptionsToConfig, []},
      {Credo.Execution.Task.InitializePlugins, []}
    ],
    parse_cli_options: [
      {Credo.Execution.Task.ParseOptions, []}
    ],
    initialize_plugins: [
      # This is where plugins can "put" their hooks using `Credo.Plugin.append_task/3`
      # to initialize themselves based on the params given in the config as well as
      # in their own command line switches.
      #
      # Example:
      #
      #     defmodule CredoDemoPlugin do
      #       import Credo.Plugin
      #
      #       def init(exec) do
      #         append_task(exec, :initialize_plugins, CredoDemoPlugin.SetDiffAsDefaultCommand)
      #       end
      #     end
    ],
    validate_cli_options: [
      {Credo.Execution.Task.ValidateOptions, []}
    ],
    convert_cli_options_to_config: [
      {Credo.Execution.Task.ConvertCLIOptionsToConfig, []}
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
  ]

  alias Credo.Execution.ExecutionConfigFiles
  alias Credo.Execution.ExecutionIssues
  alias Credo.Execution.ExecutionSourceFiles
  alias Credo.Execution.ExecutionTiming

  @doc "Builds an Execution struct for a re-run with the the given `argv`, noting to just analyse the `files_that_changed`."
  def build(%__MODULE__{} = previous_exec, files_that_changed) when is_list(files_that_changed) do
    previous_exec.argv
    |> build()
    |> put_rerun(previous_exec, files_that_changed)
  end

  def build(argv, files_that_changed) when is_list(files_that_changed) do
    build(argv)
  end

  @doc "Builds an Execution struct for the the given `argv`."
  def build(argv \\ []) when is_list(argv) do
    max_concurrent_check_runs = System.schedulers_online()

    %__MODULE__{argv: argv, max_concurrent_check_runs: max_concurrent_check_runs}
    |> put_pipeline(@execution_pipeline_key, @execution_pipeline)
    |> put_builtin_command("categories", Credo.CLI.Command.Categories.CategoriesCommand)
    |> put_builtin_command("diff", Credo.CLI.Command.Diff.DiffCommand)
    |> put_builtin_command("explain", Credo.CLI.Command.Explain.ExplainCommand)
    |> put_builtin_command("gen.check", Credo.CLI.Command.GenCheck)
    |> put_builtin_command("gen.config", Credo.CLI.Command.GenConfig)
    |> put_builtin_command("help", Credo.CLI.Command.Help)
    |> put_builtin_command("info", Credo.CLI.Command.Info.InfoCommand)
    |> put_builtin_command("list", Credo.CLI.Command.List.ListCommand)
    |> put_builtin_command("suggest", Credo.CLI.Command.Suggest.SuggestCommand)
    |> put_builtin_command("version", Credo.CLI.Command.Version)
    |> start_servers()
  end

  @doc false
  defp start_servers(%__MODULE__{} = exec) do
    exec
    |> ExecutionConfigFiles.start_server()
    |> ExecutionIssues.start_server()
    |> ExecutionSourceFiles.start_server()
    |> ExecutionTiming.start_server()
  end

  @doc """
  Returns the checks that should be run for a given `exec` struct.

  Takes all checks from the `checks:` field of the exec, matches those against
  any patterns to include or exclude certain checks given via the command line.
  """
  def checks(exec)

  def checks(%__MODULE__{checks: nil}) do
    {[], [], []}
  end

  def checks(%__MODULE__{
        checks: checks,
        only_checks: only_checks,
        only_checks_tags: only_checks_tags,
        ignore_checks: ignore_checks,
        ignore_checks_tags: ignore_checks_tags
      }) do
    only_matching =
      checks |> filter_only_checks_by_tags(only_checks_tags) |> filter_only_checks(only_checks)

    ignore_matching_by_name = filter_ignore_checks(checks, ignore_checks)
    ignore_matching_by_tags = filter_ignore_checks_by_tags(checks, ignore_checks_tags)
    ignore_matching = ignore_matching_by_name ++ ignore_matching_by_tags

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

  defp filter_only_checks_by_tags(checks, nil), do: checks
  defp filter_only_checks_by_tags(checks, []), do: checks
  defp filter_only_checks_by_tags(checks, tags), do: filter_checks_by_tags(checks, tags)

  defp filter_ignore_checks_by_tags(_checks, nil), do: []
  defp filter_ignore_checks_by_tags(_checks, []), do: []
  defp filter_ignore_checks_by_tags(checks, tags), do: filter_checks_by_tags(checks, tags)

  defp filter_checks_by_tags(_checks, nil), do: []
  defp filter_checks_by_tags(_checks, []), do: []

  defp filter_checks_by_tags(checks, tags) do
    tags = Enum.map(tags, &String.to_atom/1)

    Enum.filter(checks, &match_tags(&1, tags, true))
  end

  defp match_tags(_tuple, [], default_for_empty), do: default_for_empty

  defp match_tags({check, params}, tags, _default_for_empty) do
    tags_for_check = tags_for_check(check, params)

    Enum.any?(tags, &Enum.member?(tags_for_check, &1))
  end

  @doc """
  Returns the tags for a given `check` and its `params`.
  """
  def tags_for_check(check, params)

  def tags_for_check(check, nil), do: check.tags
  def tags_for_check(check, []), do: check.tags

  def tags_for_check(check, params) when is_list(params) do
    params
    |> Credo.Check.Params.tags(check)
    |> Enum.flat_map(fn
      :__initial__ -> check.tags
      tag -> [tag]
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
    Map.get(exec.commands, name) ||
      raise ~S'Command not found: "#{name}"\n\nRegistered commands: #{
              inspect(exec.commands, pretty: true)
            }'
  end

  @doc false
  def put_command(exec, _plugin_mod, name, command_mod) do
    commands = Map.put(exec.commands, name, command_mod)

    %__MODULE__{exec | commands: commands}
    |> init_command(command_mod)
  end

  @doc false
  def set_initializing_plugin(%__MODULE__{initializing_plugin: nil} = exec, plugin_mod) do
    %__MODULE__{exec | initializing_plugin: plugin_mod}
  end

  def set_initializing_plugin(exec, nil) do
    %__MODULE__{exec | initializing_plugin: nil}
  end

  def set_initializing_plugin(%__MODULE__{initializing_plugin: mod1}, mod2) do
    raise "Attempting to initialize plugin #{inspect(mod2)}, " <>
            "while already initializing plugin #{mod1}"
  end

  # Plugin params

  def get_plugin_param(exec, plugin_mod, param_name) do
    exec.plugins[plugin_mod][param_name]
  end

  def put_plugin_param(exec, plugin_mod, param_name, param_value) do
    plugins =
      Keyword.update(exec.plugins, plugin_mod, [], fn list ->
        Keyword.update(list, param_name, param_value, fn _ -> param_value end)
      end)

    %__MODULE__{exec | plugins: plugins}
  end

  # CLI switches

  @doc false
  def put_cli_switch(exec, _plugin_mod, name, type) do
    %__MODULE__{exec | cli_switches: exec.cli_switches ++ [{name, type}]}
  end

  @doc false
  def put_cli_switch_alias(exec, _plugin_mod, name, alias_name) do
    %__MODULE__{exec | cli_aliases: exec.cli_aliases ++ [{alias_name, name}]}
  end

  @doc false
  def put_cli_switch_plugin_param_converter(exec, plugin_mod, cli_switch_name, plugin_param_name) do
    converter_tuple = {cli_switch_name, plugin_mod, plugin_param_name}

    %__MODULE__{
      exec
      | cli_switch_plugin_param_converters:
          exec.cli_switch_plugin_param_converters ++ [converter_tuple]
    }
  end

  def get_given_cli_switch(exec, switch_name) do
    if Map.has_key?(exec.cli_options.switches, switch_name) do
      {:ok, exec.cli_options.switches[switch_name]}
    else
      :error
    end
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

  # Config Files

  @doc "Returns all config files for the given `exec` struct."
  def get_config_files(exec) do
    Credo.Execution.ExecutionConfigFiles.get(exec)
  end

  @doc false
  def append_config_file(exec, {_, _, _} = config_file) do
    config_files = get_config_files(exec) ++ [config_file]

    ExecutionConfigFiles.put(exec, config_files)

    exec
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

  @doc "Returns all issues for the given `exec` struct that relate to the given `filename`."
  def get_issues(exec, filename) do
    exec
    |> ExecutionIssues.to_map()
    |> Map.get(filename, [])
  end

  @doc "Sets the issues for the given `exec` struct, overwriting any existing issues."
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

  @doc "Halts further execution of the pipeline."
  def halt(exec) do
    %__MODULE__{exec | halted: true}
  end

  @doc false
  def halt(exec, halt_message) do
    %__MODULE__{exec | halted: true}
    |> put_halt_message(halt_message)
  end

  @doc false
  def get_halt_message(exec) do
    get_assign(exec, "credo.halt_message")
  end

  @doc false
  def put_halt_message(exec, halt_message) do
    put_assign(exec, "credo.halt_message", halt_message)
  end

  # Task tracking

  @doc false
  def set_parent_and_current_task(exec, parent_task, current_task) do
    %__MODULE__{exec | parent_task: parent_task, current_task: current_task}
  end

  # Running tasks

  @doc false
  def run(exec) do
    run_pipeline(exec, __MODULE__)
  end

  @doc false
  def run_pipeline(%__MODULE__{} = initial_exec, pipeline_key)
      when is_atom(pipeline_key) and not is_nil(pipeline_key) do
    initial_pipeline = get_pipeline(initial_exec, pipeline_key)

    Enum.reduce(initial_pipeline, initial_exec, fn {group_name, _list}, exec_inside_pipeline ->
      outer_pipeline = get_pipeline(exec_inside_pipeline, pipeline_key)

      task_group = outer_pipeline[group_name]

      Enum.reduce(task_group, exec_inside_pipeline, fn {task_mod, opts}, exec_inside_task_group ->
        Credo.Execution.Task.run(task_mod, exec_inside_task_group, opts)
      end)
    end)
  end

  @doc false
  defp get_pipeline(exec, pipeline_key) do
    case exec.pipeline_map[pipeline_key] do
      nil -> raise "Could not find execution pipeline for '#{pipeline_key}'"
      pipeline -> pipeline
    end
  end

  def put_pipeline(exec, pipeline_key, pipeline) do
    new_pipelines = Map.put(exec.pipeline_map, pipeline_key, pipeline)

    %__MODULE__{exec | pipeline_map: new_pipelines}
  end

  @doc false
  def prepend_task(exec, plugin_mod, nil, group_name, task_tuple) do
    prepend_task(exec, plugin_mod, @execution_pipeline_key, group_name, task_tuple)
  end

  def prepend_task(exec, plugin_mod, pipeline_key, group_name, task_mod) when is_atom(task_mod) do
    prepend_task(exec, plugin_mod, pipeline_key, group_name, {task_mod, []})
  end

  @doc false
  def prepend_task(exec, _plugin_mod, pipeline_key, group_name, task_tuple) do
    pipeline =
      exec
      |> get_pipeline(pipeline_key)
      |> Enum.map(fn
        {^group_name, list} -> {group_name, [task_tuple] ++ list}
        value -> value
      end)

    put_pipeline(exec, __MODULE__, pipeline)
  end

  @doc false
  def append_task(exec, plugin_mod, nil, group_name, task_tuple) do
    append_task(exec, plugin_mod, __MODULE__, group_name, task_tuple)
  end

  def append_task(exec, plugin_mod, pipeline_key, group_name, task_mod) when is_atom(task_mod) do
    append_task(exec, plugin_mod, pipeline_key, group_name, {task_mod, []})
  end

  @doc false
  def append_task(exec, _plugin_mod, pipeline_key, group_name, task_tuple) do
    pipeline =
      exec
      |> get_pipeline(pipeline_key)
      |> Enum.map(fn
        {^group_name, list} -> {group_name, list ++ [task_tuple]}
        value -> value
      end)

    put_pipeline(exec, pipeline_key, pipeline)
  end

  defp put_builtin_command(exec, name, command_mod) do
    put_command(exec, Credo, name, command_mod)
  end

  defp init_command(exec, command_mod) do
    exec
    |> command_mod.init()
    |> ensure_execution_struct("#{command_mod}.init/1")
  end

  @doc ~S"""
  Ensures that the given `value` is a `%Credo.Execution{}` struct, raises an error otherwise.

  Example:

      exec
      |> mod.init()
      |> Execution.ensure_execution_struct("#{mod}.init/1")
  """
  def ensure_execution_struct(value, fun_name)

  def ensure_execution_struct(%__MODULE__{} = exec, _fun_name), do: exec

  def ensure_execution_struct(value, fun_name) do
    raise("Expected #{fun_name} to return %Credo.Execution{}, got: #{inspect(value)}")
  end

  @doc false
  def get_rerun(exec) do
    case get_assign(exec, "credo.rerun.previous_execution") do
      nil -> :notfound
      previous_exec -> {previous_exec, get_assign(exec, "credo.rerun.files_that_changed")}
    end
  end

  defp put_rerun(exec, previous_exec, files_that_changed) do
    exec
    |> put_assign("credo.rerun.previous_execution", previous_exec)
    |> put_assign(
      "credo.rerun.files_that_changed",
      Enum.map(files_that_changed, fn filename ->
        filename
        |> Path.expand()
        |> Path.relative_to_cwd()
      end)
    )
  end
end
