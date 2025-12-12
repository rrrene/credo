defmodule Credo.Check.Refactor.IoPuts do
  use Credo.Check,
    id: "EX4011",
    tags: [:controversial],
    explanations: [
      check: """
      Prefer using Logger statements over using `IO.puts/1`.

      This is a situational check.

      As such, it might be a great help for e.g. Phoenix projects, but
      a clear mismatch for CLI projects.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({{:., _, [{:__aliases__, meta, [:IO]}, :puts]}, _, _} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta) do
    format_issue(
      ctx,
      message: "There should be no calls to `IO.puts/1`.",
      trigger: "IO.puts",
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
