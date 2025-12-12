defmodule Credo.Check.Refactor.MapInto do
  # only available in Elixir < 1.8 since performance improvements have since made this check obsolete
  use Credo.Check,
    id: "EX4013",
    base_priority: :high,
    elixir_version: "< 1.8.0",
    explanations: [
      check: """
      `Enum.into/3` is more efficient than `Enum.map/2 |> Enum.into/2`.

      This should be refactored:

          [:apple, :banana, :carrot]
          |> Enum.map(&({&1, to_string(&1)}))
          |> Enum.into(%{})

      to look like this:

          Enum.into([:apple, :banana, :carrot], %{}, &({&1, to_string(&1)}))

      The reason for this is performance, because the separate calls to
      `Enum.map/2` and `Enum.into/2` require two iterations whereas
      `Enum.into/3` only requires one.

      **NOTE**: This check is only available in Elixir < 1.8 since performance
      improvements have since made this check obsolete.
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
         {{:., _, [{:__aliases__, meta, [:Enum]}, :into]}, _,
          [{{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _}, _]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "Enum.into"))}
  end

  defp walk(
         {:|>, _,
          [
            {{:., _, [{:__aliases__, _, [:Enum]}, :map]}, _, _},
            {{:., _, [{:__aliases__, meta, [:Enum]}, :into]}, _, _}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta, "Enum.into"))}
  end

  defp walk(
         {{:., meta, [{:__aliases__, _, [:Enum]}, :into]}, _,
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
            {{:., _, [{:__aliases__, _, [:Enum]}, :into]}, _, into_args}
          ]} = ast,
         ctx
       )
       when length(into_args) == 1 do
    {ast, put_issue(ctx, issue_for(ctx, meta, "|>"))}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta, trigger) do
    format_issue(
      ctx,
      message: "`Enum.into/3` is more efficient than `Enum.map/2 |> Enum.into/2`.",
      line_no: meta[:line],
      trigger: trigger
    )
  end
end
