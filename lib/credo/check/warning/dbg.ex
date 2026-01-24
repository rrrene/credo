defmodule Credo.Check.Warning.Dbg do
  use Credo.Check,
    id: "EX5026",
    base_priority: :high,
    elixir_version: ">= 1.14.0-dev",
    param_defaults: [allow_capture: false],
    explanations: [
      check: """
      Calls to dbg/0 and dbg/2 should mostly be used during debugging sessions.

      This check warns about those calls, because they probably have been committed
      in error.
      """,
      params: [
        allow_capture: "Allow using a capture, e.g. `&dbg/1`."
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:@, _, [{:dbg, _, _}]}, ctx) do
    {nil, ctx}
  end

  defp walk({:dbg, meta, []} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "dbg"))}
  end

  defp walk({:dbg, meta, [_single_param]} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "dbg"))}
  end

  defp walk({:dbg, meta, [_first_param, _second_param]} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "dbg"))}
  end

  defp walk(
         {{:., _, [{:__aliases__, meta, [:"Elixir", :Kernel]}, :dbg]}, _, _args} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "Elixir.Kernel.dbg"))}
  end

  defp walk({{:., _, [{:__aliases__, meta, [:Kernel]}, :dbg]}, _, _args} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "Kernel.dbg"))}
  end

  defp walk(
         {:&, _, [{:/, _, [{:dbg, _meta, _}, _arity]}]} = ast,
         %{params: %{allow_capture: true}} = ctx
       ) do
    {ast, ctx}
  end

  defp walk({:&, _, [{:/, _, [{:dbg, meta, _}, _arity]}]} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "dbg"))}
  end

  defp walk({:|>, _, [_, {:dbg, meta, nil}]} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "dbg"))}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(issue_meta, meta, trigger) do
    format_issue(
      issue_meta,
      message: "There should be no calls to `dbg/1`.",
      trigger: trigger,
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
