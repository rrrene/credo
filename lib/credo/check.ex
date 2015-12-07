defmodule Credo.Check do
  @base_priority_map  %{ignore: -100, low: -10, normal: 1, high: +10, higher: +20}
  @base_category_exit_status_map %{
    consistency: 1,
    design: 2,
    readability: 4,
    refactor: 8,
    warning: 16,
  }

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
        source_file = IssueMeta.source_file(issue_meta)
        params = IssueMeta.params(issue_meta)
        priority =
          case params[:priority] do
            nil -> base_priority
            val -> val |> Check.to_priority
          end
        exit_status =
          case params[:exit_status] do
            nil -> category |> Check.to_exit_status
            val -> val |> Check.to_exit_status
          end

        line_no = opts[:line_no]
        trigger = opts[:trigger]
        column = opts[:column]
        severity = opts[:severity] || Severity.default_value
        issue = %Issue{
          priority: priority,
          filename: source_file.filename,
          message: opts[:message],
          trigger: trigger,
          line_no: line_no,
          column: column,
          severity: severity,
          exit_status: exit_status
        }
        if line_no do
          {_def, scope} = CodeHelper.scope_for(source_file, line: line_no)
          issue =
            %Issue{
              issue |
              priority: issue.priority + priority_for(source_file, scope),
              scope: scope
            }
        end
        if trigger && line_no && !column do
          issue =
            %Issue{
              issue |
              column: SourceFile.column(source_file, line_no, trigger)
            }
        end
        format_issue(issue)
      end
      def format_issue(issue \\ %Issue{}) do
        %Issue{
          issue |
          check: __MODULE__,
          category: category
        }
      end

      defp priority_for(source_file, scope) do
        scope_prio_map = Priority.scope_priorities(source_file)
        scope_prio_map[scope] || 0
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
end
