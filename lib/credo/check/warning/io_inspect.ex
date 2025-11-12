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
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk(
         {{:., _, [{:__aliases__, meta, [:"Elixir", :IO]}, :inspect]}, _, args} = ast,
         ctx
       )
       when length(args) < 3 do
    {ast, put_issue(ctx, issue_for(ctx, meta, "Elixir.IO.inspect"))}
  end

  defp walk(
         {{:., _, [{:__aliases__, meta, [:IO]}, :inspect]}, _, args} = ast,
         ctx
       )
       when length(args) < 3 do
    {ast, put_issue(ctx, issue_for(ctx, meta, "IO.inspect"))}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta, trigger) do
    format_issue(
      ctx,
      message: "There should be no calls to `IO.inspect/1`.",
      trigger: trigger,
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
