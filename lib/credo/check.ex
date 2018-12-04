defmodule Credo.Check do
  @moduledoc """
  `Check` modules represent the checks which are run during Credo's analysis.

  Example:

      defmodule MyCheck do
        use Credo.Check, category: :warning, base_priority: :high

        def run(source_file, params) do
          #
        end
      end

  The `run/2` function takes two parameters: a source file and a list of parameters for the check.
  It has to return a list of found issues.
  """

  @type t :: module

  @doc """
  Returns the base priority for the check.
  """
  @callback base_priority() :: integer

  @doc """
  Returns the category for the check.
  """
  @callback category() :: atom

  # @callback run(source_file :: Credo.SourceFile.t, params :: Keyword.t) :: List.t

  @callback run_on_all?() :: boolean

  @callback explanation() :: String.t()

  @callback explanation_for_params() :: Keyword.t()

  @callback format_issue(issue_meta :: IssueMeta, opts :: Keyword.t()) :: Issue.t()

  @base_category_exit_status_map %{
    consistency: 1,
    design: 2,
    readability: 4,
    refactor: 8,
    warning: 16
  }

  alias Credo.Check
  alias Credo.Code.Scope
  alias Credo.Issue
  alias Credo.IssueMeta
  alias Credo.Priority
  alias Credo.Service.SourceFileScopes
  alias Credo.Severity
  alias Credo.SourceFile

  @doc false
  defmacro __using__(opts) do
    quote do
      @behaviour Credo.Check
      @before_compile Credo.Check

      alias Credo.Check
      alias Credo.Check.CodeHelper
      alias Credo.Check.Params
      alias Credo.CLI.ExitStatus
      alias Credo.Issue
      alias Credo.IssueMeta
      alias Credo.Priority
      alias Credo.Severity
      alias Credo.SourceFile

      def base_priority do
        unquote(Priority.to_integer(opts[:base_priority]))
      end

      def category do
        unquote(category_body(opts[:category]) || :unknown)
      end

      def elixir_version do
        unquote(opts[:elixir_version] || ">= 0.0.1")
      end

      def run_on_all? do
        unquote(run_on_all_body(opts[:run_on_all]))
      end

      def explanation do
        Check.explanation_for(@explanation, :check)
      end

      def explanation_for_params do
        Check.explanation_for(@explanation, :params) || []
      end

      def format_issue(issue_meta, opts) do
        Check.format_issue(
          issue_meta,
          opts,
          category(),
          base_priority(),
          __MODULE__
        )
      end
    end
  end

  @doc false
  defmacro __before_compile__(env) do
    quote do
      unquote(default_params_module_attribute(env))

      def params_defaults do
        @default_params
      end

      def params_names do
        Keyword.keys(params_defaults())
      end
    end
  end

  defp default_params_module_attribute(env) do
    if env.module |> Module.get_attribute(:default_params) |> is_nil() do
      quote do
        @default_params []
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
  - `:line_no`      Sets the issue's line number.
                      Tries to find `column` if `:trigger` is supplied.
  - `:column`       Sets the issue's column.
  - `:exit_status`  Sets the issue's exit_status.
  - `:severity`     Sets the issue's severity.
  """
  def format_issue(issue_meta, opts, issue_category, issue_base_priority, check) do
    source_file = IssueMeta.source_file(issue_meta)
    params = IssueMeta.params(issue_meta)

    priority =
      case params[:priority] do
        nil -> issue_base_priority
        val -> Priority.to_integer(val)
      end

    exit_status =
      case params[:exit_status] do
        nil -> Check.to_exit_status(issue_category)
        val -> Check.to_exit_status(val)
      end

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
  defp scope_for(source_file, line: line_no) do
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
  defp scope_list(%SourceFile{filename: filename} = source_file) do
    case SourceFileScopes.get(filename) do
      {:ok, value} ->
        value

      :notfound ->
        ast = SourceFile.ast(source_file)
        lines = SourceFile.lines(source_file)

        result =
          Enum.map(lines, fn {line_no, _} ->
            Scope.name(ast, line: line_no)
          end)

        SourceFileScopes.put(filename, result)

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

  def to_exit_status(value), do: value

  defp run_on_all_body(true), do: true
  defp run_on_all_body(_), do: false
end
