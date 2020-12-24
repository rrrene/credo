defmodule Credo.Check do
  @moduledoc """
  `Check` modules represent the checks which are run during Credo's analysis.

  Example:

      defmodule MyCheck do
        use Credo.Check, category: :warning, base_priority: :high

        def run(%SourceFile{} = source_file, params) do
          #
        end
      end

  The check can be configured by passing the following
  options to `use Credo.Check`:

  - `:base_priority`  Sets the checks's base priority (`:low`, `:normal`, `:high`, `:higher` or `:ignore`).
  - `:category`       Sets the check's category (`:consistency`, `:design`, `:readability`, `:refactor`  or `:warning`).
  - `:elixir_version` Sets the check's version requirement for Elixir (defaults to `>= 0.0.1`).
  - `:explanations`   Sets explanations displayed for the check, e.g.

      ```elixir
      [
        check: "...",
        params: [
          param1: "Your favorite number",
          param2: "Online/Offline mode"
        ]
      ]
      ```

  - `:param_defaults` Sets the default values for the check's params (e.g. `[param1: 42, param2: "offline"]`)
  - `:tags`           Sets the tags for this check (list of atoms, e.g. `[:tag1, :tag2]`)

  Please also note that these options to `use Credo.Check` are just a convenience to implement the `Credo.Check`
  behaviour. You can implement any of these by hand:

      defmodule MyCheck do
        use Credo.Check

        def category, do: :warning

        def base_priority, do: :high

        def explanations do
          [
            check: "...",
            params: [
              param1: "Your favorite number",
              param2: "Online/Offline mode"
            ]
          ]
        end

        def param_defaults, do: [param1: 42, param2: "offline"]

        def run(%SourceFile{} = source_file, params) do
          #
        end
      end

  The `run/2` function of a Check module takes two parameters: a source file and a list of parameters for the check.
  It has to return a list of found issues.
  """

  @doc """
  Runs the current check on all `source_files` by calling `run_on_source_file/3`.

  If you are developing a check that has to run on all source files, you can overwrite `run_on_all_source_files/3`:

      defmodule MyCheck do
        use Credo.Check

        def run_on_all_source_files(exec, source_files, params) do
          issues =
            source_files
            |> do_something_crazy()
            |> do_something_crazier()

          append_issues_and_timings(exec, issues)

          :ok
        end
      end

  Check out Credo's checks from the consistency category for examples of these kinds of checks.
  """
  @callback run_on_all_source_files(
              exec :: Credo.Execution.t(),
              source_files :: list(Credo.SourceFile.t()),
              params :: Keyword.t()
            ) :: :ok

  @doc """
  Runs the current check on a single `source_file` and appends the resulting issues to the current `exec`.
  """
  @callback run_on_source_file(
              exec :: Credo.Execution.t(),
              source_file :: Credo.SourceFile.t(),
              params :: Keyword.t()
            ) :: :ok

  @callback run(source_file :: Credo.SourceFile.t(), params :: Keyword.t()) ::
              list(Credo.Issue.t())

  @doc """
  Returns the base priority for the check.

  This can be one of `:higher`, `:high`, `:normal`, `:low` or `:ignore`
  (technically it can also be  or an integer, but these are internal representations although that is not recommended).
  """
  @callback base_priority() :: :higher | :high | :normal | :low | :ignore | integer

  @doc """
  Returns the category for the check.
  """
  @callback category() :: atom

  @doc """
  Returns the required Elixir version for the check.
  """
  @callback elixir_version() :: String.t()

  @doc """
  Returns the exit status for the check.
  """
  @callback exit_status() :: integer

  @doc """
  Returns the explanations for the check and params as a keyword list.
  """
  @callback explanations() :: Keyword.t()

  @doc """
  Returns the default values for the check's params as a keyword list.
  """
  @callback param_defaults() :: Keyword.t()

  # @callback run(source_file :: Credo.SourceFile.t, params :: Keyword.t) :: list()

  @doc """
  Returns wether or not this check runs on all source files.
  """
  @callback run_on_all?() :: boolean

  @doc """
  Returns the tags for the check.
  """
  @callback tags() :: list(atom)

  @doc false
  @callback format_issue(issue_meta :: Credo.IssueMeta.t(), opts :: Keyword.t()) ::
              Credo.Issue.t()

  @base_category_exit_status_map %{
    consistency: 1,
    design: 2,
    readability: 4,
    refactor: 8,
    warning: 16
  }

  alias Credo.Check
  alias Credo.Check.Params
  alias Credo.Code.Scope
  alias Credo.Issue
  alias Credo.IssueMeta
  alias Credo.Priority
  alias Credo.Service.SourceFileScopes
  alias Credo.Severity
  alias Credo.SourceFile

  @valid_use_opts [
    :base_priority,
    :category,
    :elixir_version,
    :exit_status,
    :explanations,
    :param_defaults,
    :run_on_all,
    :tags
  ]

  @doc false
  defmacro __using__(opts) do
    Enum.each(opts, fn
      {key, _name} when key not in @valid_use_opts ->
        raise "Could not find key `#{key}` in #{inspect(@valid_use_opts)}"

      _ ->
        nil
    end)

    def_base_priority =
      if opts[:base_priority] do
        quote do
          @impl true
          def base_priority, do: unquote(opts[:base_priority])
        end
      else
        quote do
          @impl true
          def base_priority, do: 0
        end
      end

    def_category =
      if opts[:category] do
        quote do
          @impl true
          def category, do: unquote(category_body(opts[:category]))
        end
      else
        quote do
          @impl true
          def category, do: unquote(category_body(nil))
        end
      end

    def_elixir_version =
      if opts[:elixir_version] do
        quote do
          @impl true
          def elixir_version do
            unquote(opts[:elixir_version])
          end
        end
      else
        quote do
          @impl true
          def elixir_version, do: ">= 0.0.1"
        end
      end

    def_exit_status =
      if opts[:exit_status] do
        quote do
          @impl true
          def exit_status do
            unquote(opts[:exit_status])
          end
        end
      else
        quote do
          @impl true
          def exit_status, do: Credo.Check.to_exit_status(category())
        end
      end

    def_run_on_all? =
      if opts[:run_on_all] do
        quote do
          @impl true
          def run_on_all?, do: unquote(opts[:run_on_all] == true)
        end
      else
        quote do
          @impl true
          def run_on_all?, do: false
        end
      end

    def_param_defaults =
      if opts[:param_defaults] do
        quote do
          @impl true
          def param_defaults, do: unquote(opts[:param_defaults])
        end
      end

    def_explanations =
      if opts[:explanations] do
        quote do
          @impl true
          def explanations do
            unquote(opts[:explanations])
          end
        end
      end

    def_tags =
      quote do
        @impl true
        def tags do
          unquote(opts[:tags] || [])
        end
      end

    quote do
      @moduledoc unquote(moduledoc(opts))
      @behaviour Credo.Check
      @before_compile Credo.Check

      @use_deprecated_run_on_all? false

      alias Credo.Check
      alias Credo.Check.Params
      alias Credo.CLI.ExitStatus
      alias Credo.CLI.Output.UI
      alias Credo.Execution
      alias Credo.Execution.ExecutionTiming
      alias Credo.Issue
      alias Credo.IssueMeta
      alias Credo.Priority
      alias Credo.Severity
      alias Credo.SourceFile

      unquote(def_base_priority)
      unquote(def_category)
      unquote(def_elixir_version)
      unquote(def_exit_status)
      unquote(def_run_on_all?)
      unquote(def_param_defaults)
      unquote(def_explanations)
      unquote(def_tags)

      @impl true
      def format_issue(issue_meta, issue_options) do
        Check.format_issue(
          issue_meta,
          issue_options,
          __MODULE__
        )
      end

      @doc false
      @impl true
      def run_on_all_source_files(exec, source_files, params \\ [])

      @impl true
      def run_on_all_source_files(exec, source_files, params) do
        if function_exported?(__MODULE__, :run, 3) do
          IO.warn(
            "Defining `run(source_files, exec, params)` for checks that run on all source files is deprecated. " <>
              "Define `run_on_all_source_files(exec, source_files, params)` instead."
          )

          apply(__MODULE__, :run, [source_files, exec, params])
        else
          do_run_on_all_source_files(exec, source_files, params)
        end
      end

      defp do_run_on_all_source_files(exec, source_files, params) do
        source_files
        |> Enum.map(&Task.async(fn -> run_on_source_file(exec, &1, params) end))
        |> Enum.each(&Task.await(&1, :infinity))

        :ok
      end

      @doc false
      @impl true
      def run_on_source_file(exec, source_file, params \\ [])

      def run_on_source_file(%Execution{debug: true} = exec, source_file, params) do
        ExecutionTiming.run(&do_run_on_source_file/3, [exec, source_file, params])
        |> ExecutionTiming.append(exec,
          task: exec.current_task,
          check: __MODULE__,
          filename: source_file.filename
        )
      end

      def run_on_source_file(exec, source_file, params) do
        do_run_on_source_file(exec, source_file, params)
      end

      defp do_run_on_source_file(exec, source_file, params) do
        issues =
          try do
            run(source_file, params)
          rescue
            error ->
              UI.warn("Error while running #{__MODULE__} on #{source_file.filename}")

              if exec.crash_on_error do
                reraise error, __STACKTRACE__
              else
                []
              end
          end

        append_issues_and_timings(issues, exec)

        :ok
      end

      @doc false
      @impl true
      def run(source_file, params)

      def run(%SourceFile{} = source_file, params) do
        throw("Implement me")
      end

      defoverridable Credo.Check

      defp append_issues_and_timings([] = _issues, exec) do
        exec
      end

      defp append_issues_and_timings([_ | _] = issues, exec) do
        Credo.Execution.ExecutionIssues.append(exec, issues)
      end
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    quote do
      unquote(deprecated_def_default_params(env))
      unquote(deprecated_def_explanations(env))

      @doc false
      def param_names do
        Keyword.keys(param_defaults())
      end

      @deprecated "Use param_defaults/1 instead"
      @doc false
      def params_defaults do
        # deprecated - remove module attribute
        param_defaults()
      end

      @deprecated "Use param_names/1 instead"
      @doc false
      def params_names do
        param_names()
      end

      @deprecated "Use explanations()[:check] instead"
      @doc false
      def explanation do
        # deprecated - remove module attribute
        explanations()[:check]
      end

      @deprecated "Use explanations()[:params] instead"
      @doc false
      def explanation_for_params do
        # deprecated - remove module attribute
        explanations()[:params]
      end
    end
  end

  defp moduledoc(opts) do
    explanations = opts[:explanations]

    base_priority = opts_to_string(opts[:base_priority]) || 0

    # category = opts_to_string(opts[:category]) || to_string(__MODULE__)

    elixir_version_hint =
      if opts[:elixir_version] do
        elixir_version = opts_to_string(opts[:elixir_version])

        "requires Elixir `#{elixir_version}`"
      else
        "works with any version of Elixir"
      end

    check_doc = opts_to_string(explanations[:check])
    params = explanations[:params] |> opts_to_string() |> List.wrap()
    param_defaults = opts_to_string(opts[:param_defaults])

    params_doc =
      if params == [] do
        "*There are no specific parameters for this check.*"
      else
        param_explanation =
          Enum.map(params, fn {key, value} ->
            default_value = inspect(param_defaults[key], limit: :infinity)

            default_hint =
              if default_value do
                """

                    *Defaults to* `#{default_value}`
                """
              end

            value = value |> String.split("\n") |> Enum.map(&"  #{&1}") |> Enum.join("\n")

            """
            - `#{key}`: #{value}
              #{default_hint}

            """
          end)

        """
        Use the following parameters to configure this check:

        #{param_explanation}

        """
      end

    """
    This check has a base priority of `#{base_priority}` and #{elixir_version_hint}.

    ## Explanation

    #{check_doc}

    ## Configuration parameters

    #{params_doc}

    Like with all checks, [general params](check_params.html) can be applied.

    Parameters can be configured via the [`.credo.exs` config file](config_file.html).
    """
  end

  defp opts_to_string(value) do
    {result, _} =
      value
      |> Macro.to_string()
      |> Code.eval_string()

    result
  end

  defp deprecated_def_default_params(env) do
    default_params = Module.get_attribute(env.module, :default_params)

    if is_nil(default_params) do
      if not Module.defines?(env.module, {:param_defaults, 0}) do
        quote do
          @impl true
          def param_defaults, do: []
        end
      end
    else
      # deprecated - remove once we ditch @default_params
      quote do
        @impl true
        def param_defaults do
          @default_params
        end
      end
    end
  end

  defp deprecated_def_explanations(env) do
    defines_deprecated_explanation_module_attribute? =
      !is_nil(Module.get_attribute(env.module, :explanation))

    defines_deprecated_explanations_fun? = Module.defines?(env.module, {:explanations, 0})

    if defines_deprecated_explanation_module_attribute? do
      # deprecated - remove once we ditch @explanation
      quote do
        @impl true
        def explanations do
          @explanation
        end
      end
    else
      if !defines_deprecated_explanations_fun? do
        quote do
          @impl true
          def explanations, do: []
        end
      end
    end
  end

  def explanation_for(nil, _), do: nil
  def explanation_for(keywords, key), do: keywords[key]

  @doc """
  format_issue takes an issue_meta and returns an issue.
  The resulting issue can be made more explicit by passing the following
  options to `format_issue/2`:

  - `:priority`     Sets the issue's priority.
  - `:trigger`      Sets the issue's trigger.
  - `:line_no`      Sets the issue's line number. Tries to find `column` if `:trigger` is supplied.
  - `:column`       Sets the issue's column.
  - `:exit_status`  Sets the issue's exit_status.
  - `:severity`     Sets the issue's severity.
  """
  def format_issue(issue_meta, opts, check) do
    params = IssueMeta.params(issue_meta)
    issue_category = Params.category(params, check)
    issue_base_priority = Params.priority(params, check)

    format_issue(issue_meta, opts, issue_category, issue_base_priority, check)
  end

  @doc false
  def format_issue(issue_meta, opts, issue_category, issue_priority, check) do
    source_file = IssueMeta.source_file(issue_meta)
    params = IssueMeta.params(issue_meta)

    priority = Priority.to_integer(issue_priority)

    exit_status_or_category = Params.exit_status(params, check) || issue_category
    exit_status = Check.to_exit_status(exit_status_or_category)

    line_no = opts[:line_no]
    trigger = opts[:trigger]
    column = opts[:column]
    severity = opts[:severity] || Severity.default_value()

    %Issue{
      priority: priority,
      filename: source_file.filename,
      message: opts[:message],
      trigger: trigger,
      line_no: line_no,
      column: column,
      severity: severity,
      exit_status: exit_status
    }
    |> add_line_no_options(line_no, source_file)
    |> add_column_if_missing(trigger, line_no, column, source_file)
    |> add_check_and_category(check, issue_category)
  end

  defp add_check_and_category(issue, check, issue_category) do
    %Issue{
      issue
      | check: check,
        category: issue_category
    }
  end

  defp add_column_if_missing(issue, trigger, line_no, column, source_file) do
    if trigger && line_no && !column do
      %Issue{
        issue
        | column: SourceFile.column(source_file, line_no, trigger)
      }
    else
      issue
    end
  end

  defp add_line_no_options(issue, line_no, source_file) do
    if line_no do
      {_def, scope} = scope_for(source_file, line: line_no)

      %Issue{
        issue
        | priority: issue.priority + priority_for(source_file, scope),
          scope: scope
      }
    else
      issue
    end
  end

  # Returns the scope for the given line as a tuple consisting of the call to
  # define the scope (`:defmodule`, `:def`, `:defp` or `:defmacro`) and the
  # name of the scope.
  #
  # Examples:
  #
  #     {:defmodule, "Foo.Bar"}
  #     {:def, "Foo.Bar.baz"}
  #
  @doc false
  def scope_for(source_file, line: line_no) do
    source_file
    |> scope_list
    |> Enum.at(line_no - 1)
  end

  # Returns all scopes for the given source_file per line of source code as tuple
  # consisting of the call to define the scope
  # (`:defmodule`, `:def`, `:defp` or `:defmacro`) and the name of the scope.
  #
  # Examples:
  #
  #     [
  #       {:defmodule, "Foo.Bar"},
  #       {:def, "Foo.Bar.baz"},
  #       {:def, "Foo.Bar.baz"},
  #       {:def, "Foo.Bar.baz"},
  #       {:def, "Foo.Bar.baz"},
  #       {:defmodule, "Foo.Bar"}
  #     ]
  defp scope_list(%SourceFile{} = source_file) do
    case SourceFileScopes.get(source_file) do
      {:ok, value} ->
        value

      :notfound ->
        ast = SourceFile.ast(source_file)
        lines = SourceFile.lines(source_file)
        scope_info_list = Scope.scope_info_list(ast)

        result =
          Enum.map(lines, fn {line_no, _} ->
            Scope.name_from_scope_info_list(scope_info_list, line_no)
          end)

        SourceFileScopes.put(source_file, result)

        result
    end
  end

  defp priority_for(source_file, scope) do
    scope_prio_map = Priority.scope_priorities(source_file)

    scope_prio_map[scope] || 0
  end

  defp category_body(nil) do
    quote do
      name =
        __MODULE__
        |> Module.split()
        |> Enum.at(2)

      safe_name = name || :unknown

      safe_name
      |> to_string
      |> String.downcase()
      |> String.to_atom()
    end
  end

  defp category_body(value), do: value

  @doc "Converts a given category to an exit status"
  def to_exit_status(nil), do: 0

  def to_exit_status(atom) when is_atom(atom) do
    to_exit_status(@base_category_exit_status_map[atom])
  end

  def to_exit_status(value) when is_number(value), do: value

  @doc false
  def defined?(check)

  def defined?({atom, _params}), do: defined?(atom)

  def defined?(binary) when is_binary(binary) do
    binary |> String.to_atom() |> defined?()
  end

  def defined?(module) when is_atom(module) do
    case Code.ensure_compiled(module) do
      {:module, _} -> true
      {:error, _} -> false
    end
  end
end
