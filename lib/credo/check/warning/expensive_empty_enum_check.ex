defmodule Credo.Check.Warning.ExpensiveEmptyEnumCheck do
  use Credo.Check,
    id: "EX5003",
    base_priority: :high,
    explanations: [
      # TODO: improve checkdoc
      check: """
      Checking if the size of the enum is `0` (or not `0`) can be very expensive,
      since you are determining the exact count of elements.

      Checking if an enum is empty should be done by using

          Enum.empty?(enum)

      or

          list == []


      For `Enum.count/2`: Checking if an enum doesn't contain specific elements should
      be done by using

          not Enum.any?(enum, condition)

      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__) |> Map.put(:handled_guards, MapSet.new())
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  @enum_count_pattern quote do: {
                              {:., _, [{:__aliases__, _, [:Enum]}, :count]},
                              _,
                              _
                            }
  @length_pattern quote do: {:length, _, [_]}
  @comparisons [
    {@enum_count_pattern, "Enum.count"},
    {@length_pattern, "length"}
  ]

  # <= 0 is equivalent to == 0
  # >= 0 is always true, but should be flagged.
  @operators_for_zero [:==, :!=, :===, :!==, :>, :>=, :<, :<=]

  # Handles cases like `when is_list(enum) and not is_map(enum) and length(enum) == 0`
  defp walk({:when, _meta, [_, guard_expr]} = ast, ctx) do
    {ast, find_length_comparisons_in_guard(guard_expr, ctx)}
  end

  for {pattern, trigger} <- @comparisons do
    # Comparisons against 0 (not in guards - guards are handled above)
    defp walk({op, meta, [unquote(pattern), 0]} = ast, ctx) when op in @operators_for_zero do
      handle_non_guard_comparison(ast, ctx, meta, unquote(trigger))
    end

    defp walk({op, meta, [0, unquote(pattern)]} = ast, ctx) when op in @operators_for_zero do
      handle_non_guard_comparison(ast, ctx, meta, unquote(trigger))
    end

    # Comparisons against 1
    defp walk({:>=, meta, [unquote(pattern), 1]} = ast, ctx) do
      handle_non_guard_comparison(ast, ctx, meta, unquote(trigger))
    end

    defp walk({:<=, meta, [1, unquote(pattern)]} = ast, ctx) do
      handle_non_guard_comparison(ast, ctx, meta, unquote(trigger))
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  # Match guard clauses directly - check the guard expression for length comparisons
  for {op, lhs, rhs} <-
        Enum.flat_map(@operators_for_zero, &[{&1, @length_pattern, 0}, {&1, 0, @length_pattern}]) ++
          [
            # < 1 is equivalent to == 0
            {:<, @length_pattern, 1},
            # 1 <= length is equivalent to > 0
            {:<=, 1, @length_pattern},
            # >= 1 is equivalent to != 0
            {:>=, @length_pattern, 1}
          ] do
    defp find_length_comparisons_in_guard(
           {unquote(op), comp_meta, [unquote(lhs), unquote(rhs)]},
           ctx
         ) do
      mark_guard_issue(ctx, comp_meta)
    end
  end

  # Recurse into conjunction expressions
  defp find_length_comparisons_in_guard({conjunction, _, args}, ctx)
       when conjunction in [:and, :or, :&&, :||] and is_list(args) do
    Enum.reduce(args, ctx, &find_length_comparisons_in_guard/2)
  end

  defp find_length_comparisons_in_guard({negation, _, [arg]}, ctx) when negation in [:not, :!] do
    find_length_comparisons_in_guard(arg, ctx)
  end

  defp find_length_comparisons_in_guard(_, ctx), do: ctx

  defp mark_guard_issue(ctx, comp_meta) do
    key = {comp_meta[:line], comp_meta[:column]}
    ctx = %{ctx | handled_guards: MapSet.put(ctx.handled_guards, key)}
    put_issue(ctx, issue_for(ctx, comp_meta, "length", "comparing against the empty list"))
  end

  defp handle_non_guard_comparison(ast, ctx, meta, trigger) do
    # Skip if this comparison was already handled in a guard clause
    if MapSet.member?(ctx.handled_guards, {meta[:line], meta[:column]}) do
      {ast, ctx}
    else
      {ast, put_issue(ctx, issue_for(ctx, meta, trigger, suggest(ast)))}
    end
  end

  defp suggest({_op, _, [_, {_pattern, _, args}]}), do: suggest_for_arity(Enum.count(args))
  defp suggest({_op, _, [{_pattern, _, args}, _]}), do: suggest_for_arity(Enum.count(args))

  defp suggest_for_arity(2), do: "`not Enum.any?/2`"
  defp suggest_for_arity(1), do: "`Enum.empty?/1`"

  defp issue_for(ctx, meta, trigger, suggestion) do
    format_issue(
      ctx,
      message: "Using `#{trigger}/1` is expensive, prefer #{suggestion}.",
      trigger: trigger,
      line_no: meta[:line]
    )
  end
end
