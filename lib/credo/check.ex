defmodule Credo.Check do
  @base_priority_map  %{ignore: -100, low: -10, normal: 1, high: +10, higher: +20}
  @base_category_exit_status_map %{
    consistency: 1,
    design: 2,
    readability: 4,
    refactor: 8,
    warning: 16,
  }

  alias Credo.Issue

  defmacro __using__(opts) do
    quote do
      alias Credo.Check
      alias Credo.Issue
      alias Credo.IssueMeta
      alias Credo.Priority
      alias Credo.Severity
      alias Credo.SourceFile
      alias Credo.Check.CodeHelper
      alias Credo.Check.Params
      alias Credo.CLI.ExitStatus

      def base_priority, do: unquote(to_priority(opts[:base_priority]))
      def category, do: unquote(category_body(opts[:category]))
      def run_on_all?, do: unquote(run_on_all_body(opts[:run_on_all]))

      def explanation, do: explanation_for(@explanation, :check)
      def explanation_for_params, do: explanation_for(@explanation, :params)

      defp explanation_for(nil, _), do: nil
      defp explanation_for(kw, key), do: kw[key]

      # TODO: def config_explanation(key), do: explanation_for(@explanation, key)

      def format_issue(issue_meta, opts) do
        Credo.Check.__format_issue__(issue_meta, opts, category, base_priority, __MODULE__)
      end
    end
  end

  defp category_body(nil) do
    quote do
      __MODULE__
      |> Module.split
      |> Enum.at(2)
      |> String.downcase
      |> String.to_atom
    end
  end
  defp category_body(value), do: value

  @doc "Converts a given category to a priority"
  def to_priority(nil), do: 0
  def to_priority(atom) when is_atom(atom) do
    @base_priority_map[atom]
  end
  def to_priority(value), do: value

  @doc "Converts a given category to an exit status"
  def to_exit_status(nil), do: 0
  def to_exit_status(atom) when is_atom(atom) do
    @base_category_exit_status_map[atom]
  end
  def to_exit_status(value), do: value

  defp run_on_all_body(true), do: true
  defp run_on_all_body(_), do: false

  def __format_issue__(issue_meta, opts, category, base_priority, module) do
    source_file = Credo.IssueMeta.source_file(issue_meta)
    params = Credo.IssueMeta.params(issue_meta)
    exit_status = to_exit_status(params[:exit_status] || category)
    line_no = opts[:line_no]
    trigger = opts[:trigger]
    severity = opts[:severity] || Credo.Severity.default_value
    scope = if line_no do
      {_def, scope} = Credo.Check.CodeHelper.scope_for(source_file, line: line_no)
      scope
    else
      nil
    end
    priority = to_priority(params[:priority] || base_priority) + priority_for(source_file, scope)
    column = if trigger && line_no && !opts[:column] do
      Credo.SourceFile.column(source_file, line_no, trigger)
    else
      opts[:column]
    end
    %Issue{
      priority: priority,
      filename: source_file.filename,
      message: opts[:message],
      trigger: trigger,
      line_no: line_no,
      column: column,
      severity: severity,
      exit_status: exit_status,
      category: category,
      check: module
    }
  end

  defp priority_for(source_file, scope) do
    scope_prio_map = Credo.Priority.scope_priorities(source_file)
    scope_prio_map[scope] || 0
  end
end
