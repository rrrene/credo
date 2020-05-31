defmodule Credo.Check.Readability.ExprPipe do
  use Credo.Check,
    base_priority: :high,
    tags: [:controversial],
    explanations: [
      check: """
      Pipes (`|>`) should not be used with case, if, or unless expressions.

      # TODO: Better docs here.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    {_continue, issues} =
      Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta), {true, []})

    issues
  end

  defp traverse({:|>, meta, [_, {expr, _, _}]} = ast, {true, issues}, issue_meta)
       when expr in [:case, :if, :unless] do
    {
      ast,
      {false, issues ++ [issue_for(issue_meta, meta[:line], "|>")]}
    }
  end

  defp traverse(ast, {_, issues}, _issue_meta) do
    {ast, {true, issues}}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Use a variable instead of piping to a case, if, or unless expression",
      trigger: trigger,
      line_no: line_no
    )
  end
end
