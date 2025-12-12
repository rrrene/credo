defmodule Credo.Check.Refactor.MapJoin do
  use Credo.Check,
    id: "EX4014",
    base_priority: :high,
    explanations: [
      check: """
      `Enum.map_join/3` is more efficient than `Enum.map/2 |> Enum.join/2`.

      This should be refactored:

          ["a", "b", "c"]
          |> Enum.map(&String.upcase/1)
          |> Enum.join(", ")

      to look like this:

          Enum.map_join(["a", "b", "c"], ", ", &String.upcase/1)

      The reason for this is performance, because the two separate calls
      to `Enum.map/2` and `Enum.join/2` require two iterations whereas
      `Enum.map_join/3` performs the same work in one pass.
      """
    ]

  @doc false
  def run(source_file, params \\ []) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk(
         {{:., _, [{:__aliases__, meta, [:Enum]}, :join]}, _,
          [{{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _}, _]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "Enum.join"))}
  end

  defp walk(
         {:|>, meta,
          [
            {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _},
            {{:., _, [{:__aliases__, _, [:Enum]}, :join]}, _, _}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "|>"))}
  end

  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :join]}, _,
          [
            {:|>, _, [_, {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _}]},
            _
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "|>"))}
  end

  defp walk(
         {:|>, meta,
          [
            {:|>, _,
             [
               _,
               {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _}
             ]},
            {{:., _, [{:__aliases__, _, [:Enum]}, :join]}, _, _}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "|>"))}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta, trigger) do
    format_issue(
      ctx,
      message: "`Enum.map_join/3` is more efficient than `Enum.map/2 |> Enum.join/2`.",
      line_no: meta[:line],
      trigger: trigger
    )
  end
end
