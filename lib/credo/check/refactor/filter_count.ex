defmodule Credo.Check.Refactor.FilterCount do
  use Credo.Check,
    id: "EX4030",
    base_priority: :high,
    explanations: [
      check: """
      `Enum.count/2` is more efficient than `Enum.filter/2 |> Enum.count/1`.

      This should be refactored:

          [1, 2, 3, 4, 5]
          |> Enum.filter(fn x -> rem(x, 3) == 0 end)
          |> Enum.count()

      to look like this:

          Enum.count([1, 2, 3, 4, 5], fn x -> rem(x, 3) == 0 end)

      The reason for this is performance, because the two separate calls
      to `Enum.filter/2` and `Enum.count/1` require two iterations whereas
      `Enum.count/2` performs the same work in one pass.
      """
    ]

  @doc false
  def run(source_file, params \\ []) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk(
         {:|>, _,
          [
            {:|>, _,
             [
               _,
               {{:., _, [{:__aliases__, _, [:Enum]}, :filter]}, _, _}
             ]},
            {{:., meta, [{:__aliases__, _, [:Enum]}, :count]}, _, []}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :count]}, _,
          [
            {{:., _, [{:__aliases__, _, [:Enum]}, :filter]}, _, _}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(
         {:|>, _,
          [
            {{:., _, [{:__aliases__, _, [:Enum]}, :filter]}, _, _},
            {{:., meta, [{:__aliases__, _, [:Enum]}, :count]}, _, []}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :count]}, _,
          [
            {:|>, _, [_, {{:., _, [{:__aliases__, _, [:Enum]}, :filter]}, _, _}]}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta) do
    format_issue(
      ctx,
      message: "`Enum.count/2` is more efficient than `Enum.filter/2 |> Enum.count/1`.",
      trigger: "count",
      line_no: meta[:line]
    )
  end
end
