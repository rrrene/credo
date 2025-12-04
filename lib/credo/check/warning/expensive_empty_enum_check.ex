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
    ctx = Context.build(source_file, params, __MODULE__, %{in_guard: false})
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
  @operators [:==, :!=, :===, :!==, :>, :<, :>=, :<=]

  defp walk({:when, _meta, [_, guard_expr]}, ctx) do
    ctx = Credo.Code.prewalk(guard_expr, &walk/2, %{ctx | in_guard: true})

    {nil, %{ctx | in_guard: false}}
  end

  for {pattern, trigger} <- @comparisons do
    # Comparisons against 0
    defp walk({op, meta, [unquote(pattern) = pattern, 0]} = ast, ctx) when op in @operators do
      {ast, put_issue(ctx, issue_for(ctx, meta, unquote(trigger), suggest(pattern, ctx)))}
    end

    defp walk({op, meta, [0, unquote(pattern) = pattern]} = ast, ctx) when op in @operators do
      {ast, put_issue(ctx, issue_for(ctx, meta, unquote(trigger), suggest(pattern, ctx)))}
    end

    # Comparisons against 1
    defp walk({:>=, meta, [unquote(pattern) = pattern, 1]} = ast, ctx) do
      {ast, put_issue(ctx, issue_for(ctx, meta, unquote(trigger), suggest(pattern, ctx)))}
    end

    defp walk({:<, meta, [unquote(pattern) = pattern, 1]} = ast, ctx) do
      {ast, put_issue(ctx, issue_for(ctx, meta, unquote(trigger), suggest(pattern, ctx)))}
    end

    defp walk({:<=, meta, [1, unquote(pattern) = pattern]} = ast, ctx) do
      {ast, put_issue(ctx, issue_for(ctx, meta, unquote(trigger), suggest(pattern, ctx)))}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp suggest({_pattern, _, _args}, %{in_guard: true}), do: "comparing against the empty list"
  defp suggest({_pattern, _, [_p1, _p2]}, _), do: "`not Enum.any?/2`"
  defp suggest({_pattern, _, [_p1]}, _), do: "`Enum.empty?/1`"

  defp issue_for(ctx, meta, trigger, suggestion) do
    format_issue(
      ctx,
      message: "Using `#{trigger}/1` is expensive, prefer #{suggestion}.",
      trigger: trigger,
      line_no: meta[:line]
    )
  end
end
