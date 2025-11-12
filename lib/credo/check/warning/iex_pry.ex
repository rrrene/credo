defmodule Credo.Check.Warning.IExPry do
  use Credo.Check,
    id: "EX5005",
    base_priority: :high,
    explanations: [
      check: """
      While calls to IEx.pry might appear in some parts of production code,
      most calls to this function are added during debugging sessions.

      This check warns about those calls, because they might have been committed
      in error.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({{:., _, [{:__aliases__, meta, [:IEx]}, :pry]}, _, _arguments} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta) do
    format_issue(
      ctx,
      message: "There should be no calls to `IEx.pry/0`.",
      trigger: "IEx.pry",
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
