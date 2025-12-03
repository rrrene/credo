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
    ctx = Context.build(source_file, params, __MODULE__)
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
  @operators [:==, :!=, :===, :!==, :>, :<]

  for {pattern, trigger} <- @comparisons do
    # Comparisons against 0
    defp walk({op, meta, [unquote(pattern), 0]} = ast, ctx) when op in @operators do
      {ast, put_issue(ctx, issue_for(ctx, meta, unquote(trigger), suggest(ast)))}
    end

    defp walk({op, meta, [0, unquote(pattern)]} = ast, ctx) when op in @operators do
      {ast, put_issue(ctx, issue_for(ctx, meta, unquote(trigger), suggest(ast)))}
    end

    # Comparisons against 1
    defp walk({:>=, meta, [unquote(pattern), 1]} = ast, ctx) do
      {ast, put_issue(ctx, issue_for(ctx, meta, unquote(trigger), suggest(ast)))}
    end

    defp walk({:<=, meta, [1, unquote(pattern)]} = ast, ctx) do
      {ast, put_issue(ctx, issue_for(ctx, meta, unquote(trigger), suggest(ast)))}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp suggest({_op, _, [_, {_pattern, _, args}]}), do: suggest_for_arity(Enum.count(args))
  defp suggest({_op, _, [{_pattern, _, args}, _]}), do: suggest_for_arity(Enum.count(args))

  defp suggest_for_arity(2), do: "`not Enum.any?/2`"
  defp suggest_for_arity(1), do: "`Enum.empty?/1` or `list == []`"

  defp issue_for(ctx, meta, trigger, suggestion) do
    format_issue(
      ctx,
      message: "Using `#{trigger}/1` is expensive, prefer #{suggestion}.",
      trigger: trigger,
      line_no: meta[:line]
    )
  end
end
