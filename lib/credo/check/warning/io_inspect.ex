defmodule Credo.Check.Warning.IoInspect do
  use Credo.Check,
    id: "EX5006",
    base_priority: :high,
    explanations: [
      check: """
      While calls to IO.inspect might appear in some parts of production code,
      most calls to this function are added during debugging sessions.

      This check warns about those calls, because they might have been committed
      in error.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse(
         {{:., _, [{:__aliases__, meta, [:"Elixir", :IO]}, :inspect]}, _, args} = ast,
         issues,
         issue_meta
       )
       when length(args) < 3 do
    {ast, issues_for_call(meta, "Elixir.IO.inspect", issues, issue_meta)}
  end

  defp traverse(
         {{:., _, [{:__aliases__, meta, [:IO]}, :inspect]}, _, args} = ast,
         issues,
         issue_meta
       )
       when length(args) < 3 do
    {ast, issues_for_call(meta, "IO.inspect", issues, issue_meta)}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issues_for_call(meta, trigger, issues, issue_meta) do
    [issue_for(issue_meta, meta, trigger) | issues]
  end

  defp issue_for(issue_meta, meta, trigger) do
    format_issue(
      issue_meta,
      message: "There should be no calls to `IO.inspect/1`.",
      trigger: trigger,
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
