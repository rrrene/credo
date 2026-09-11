defmodule Credo.Check.Refactor.InefficientEnumAggregations do
  use Credo.Check,
    id: "EX4035",
    base_priority: :high,
    elixir_version: ">= 1.18.0",
    explanations: [
      check: """
      `Enum.sum_by/2` and `Enum.product_by/2` can map and aggregate an
      enumerable in one pass.

      This should be refactored:

          items
          |> Enum.map(& &1.amount)
          |> Enum.sum()

      to look like this:

          Enum.sum_by(items, & &1.amount)

      The same applies to `Stream.map/2` and `Enum.product/1`.

      These functions can also aggregate map values without first building a
      list with `Map.values/1`:

          totals
          |> Map.values()
          |> Enum.sum_by(& &1.amount)

      can be refactored to:

          Enum.sum_by(totals, fn {_, value} -> value.amount end)

      `Enum.sum_by/2` and `Enum.product_by/2` were introduced in Elixir 1.18.
      """
    ]

  @aggregates [:sum, :product]
  @aggregate_bys [:sum_by, :product_by]
  @mappers [:Enum, :Stream]

  @doc false
  def run(source_file, params \\ []) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk(ast, ctx) do
    case inefficient_aggregation(ast) do
      {kind, aggregate, meta} ->
        {ast, put_issue(ctx, issue_for(ctx, meta, kind, aggregate))}

      nil ->
        {ast, ctx}
    end
  end

  defp inefficient_aggregation({{:., meta, [{:__aliases__, _, [:Enum]}, aggregate]}, _, [mapped]})
       when aggregate in @aggregates do
    if mapped?(mapped), do: {:mapped, aggregate, meta}
  end

  defp inefficient_aggregation({:|>, _, [mapped, {{:., meta, [{:__aliases__, _, [:Enum]}, aggregate]}, _, []}]})
       when aggregate in @aggregates do
    if mapped?(mapped), do: {:mapped, aggregate, meta}
  end

  defp inefficient_aggregation({{:., meta, [{:__aliases__, _, [:Enum]}, aggregate_by]}, _, [values, mapper]})
       when aggregate_by in @aggregate_bys do
    if map_values?(values) and safely_closable_mapper?(mapper),
      do: {:map_values, aggregate_by, meta}
  end

  defp inefficient_aggregation(
         {:|>, _, [values, {{:., meta, [{:__aliases__, _, [:Enum]}, aggregate_by]}, _, [mapper]}]}
       )
       when aggregate_by in @aggregate_bys do
    if map_values?(values) and safely_closable_mapper?(mapper),
      do: {:map_values, aggregate_by, meta}
  end

  defp inefficient_aggregation(_ast), do: nil

  defp mapped?({{:., _, [{:__aliases__, _, [mapper_module]}, :map]}, _, [_, _]})
       when mapper_module in @mappers,
       do: true

  defp mapped?({:|>, _, [_, {{:., _, [{:__aliases__, _, [mapper_module]}, :map]}, _, [_mapper]}]})
       when mapper_module in @mappers,
       do: true

  defp mapped?(_ast), do: false

  defp map_values?({{:., _, [{:__aliases__, _, [:Map]}, :values]}, _, [_map]}), do: true

  defp map_values?({:|>, _, [_, {{:., _, [{:__aliases__, _, [:Map]}, :values]}, _, []}]}),
    do: true

  defp map_values?(_ast), do: false

  defp safely_closable_mapper?({name, _, context})
       when is_atom(name) and (is_atom(context) or is_nil(context)),
       do: true

  defp safely_closable_mapper?({:&, _, _}), do: true
  defp safely_closable_mapper?({:fn, _, _}), do: true
  defp safely_closable_mapper?(_ast), do: false

  defp issue_for(ctx, meta, :mapped, aggregate) do
    aggregate_by = aggregate_by(aggregate)

    format_issue(ctx,
      message: "`Enum.#{aggregate_by}/2` is more efficient than mapping before `Enum.#{aggregate}/1`.",
      trigger: to_string(aggregate),
      line_no: meta[:line]
    )
  end

  defp issue_for(ctx, meta, :map_values, aggregate_by) do
    format_issue(ctx,
      message: "`Enum.#{aggregate_by}/2` can aggregate map values without `Map.values/1`.",
      trigger: to_string(aggregate_by),
      line_no: meta[:line]
    )
  end

  defp aggregate_by(:sum), do: :sum_by
  defp aggregate_by(:product), do: :product_by
end
