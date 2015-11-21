defmodule Credo.Check do
  @base_priority_map  %{ignore: -100, low: -10, normal: 1, high: +10, higher: +20}

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

      def base_priority, do: unquote(to_priority(opts[:base_priority]))
      def category, do: unquote(category_body(opts[:category]))
      def run_on_all?, do: unquote(run_on_all_body(opts[:run_on_all]))

      def explanation, do: explanation_for(@explanation, :check)
      defp explanation_for(nil, _), do: nil
      defp explanation_for(kw, key), do: kw[key]

      # TODO: def config_explanation(key), do: explanation_for(@explanation, key)

      def format_issue(issue_meta, opts) do
        source_file = IssueMeta.source_file(issue_meta)
        params = IssueMeta.params(issue_meta)
        priority =
          if params[:priority] do
            params[:priority] |> Check.to_priority
          else
            base_priority
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
          severity: severity
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

  def to_priority(nil), do: 0
  def to_priority(atom) when is_atom(atom) do
    @base_priority_map[atom]
  end
  def to_priority(value), do: value

  defp run_on_all_body(true), do: true
  defp run_on_all_body(_), do: false
end
