defmodule Credo.Check.Refactor.IoPuts do
  use Credo.Check,
    tags: [:controversial],
    explanations: [
      check: """
      Prefer using Logger statements over using `IO.puts/1`.

      This is a situational check.

      As such, it might be a great help for e.g. Phoenix projects, but
      a clear mismatch for CLI projects.
      """
    ]

  @call_string "IO.puts"

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse(
         {{:., _, [{:__aliases__, _, [:IO]}, :puts]}, meta, _arguments} = ast,
         issues,
         issue_meta
       ) do
    {ast, issues_for_call(meta, issues, issue_meta)}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issues_for_call(meta, issues, issue_meta) do
    [issue_for(issue_meta, meta[:line], @call_string) | issues]
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "There should be no calls to IO.puts/1.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
