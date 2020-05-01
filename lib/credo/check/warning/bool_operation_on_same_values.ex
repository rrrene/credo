defmodule Credo.Check.Warning.BoolOperationOnSameValues do
  use Credo.Check,
    base_priority: :high,
    explanations: [
      check: """
      Boolean operations with identical values on the left and right side are
      most probably a logical fallacy or a copy-and-paste error.

      Examples:

          x && x
          x || x
          x and x
          x or x

      Each of these cases behaves the same as if you were just writing `x`.
      """
    ]

  @ops [:and, :or, :&&, :||]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  for op <- @ops do
    defp traverse({unquote(op), meta, [lhs, rhs]} = ast, issues, issue_meta) do
      if Credo.Code.remove_metadata(lhs) === Credo.Code.remove_metadata(rhs) do
        new_issue = issue_for(issue_meta, meta[:line], unquote(op))
        {ast, issues ++ [new_issue]}
      else
        {ast, issues}
      end
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message:
        "There are identical sub-expressions to the left and to the right of the '#{trigger}' operator.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
