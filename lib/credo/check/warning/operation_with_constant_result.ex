defmodule Credo.Check.Warning.OperationWithConstantResult do
  use Credo.Check,
    id: "EX5012",
    base_priority: :high,
    explanations: [
      check: """
      Some numerical operations always yield the same result and therefore make
      little sense in production code.

      Examples:

          x * 1   # always returns x
          x * 0   # always returns 0

      In practice they are likely the result of a debugging session or were made by
      mistake.
      """
    ]

  @ops_and_constant_results [
    {:*, "zero", 0},
    {:*, "the left side of the expression", 1}
  ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # skip references to functions
  defp walk({:&, _, _}, ctx) do
    {nil, ctx}
  end

  # skip specs
  defp walk({:@, _, [{:spec, _, _}]}, ctx) do
    {nil, ctx}
  end

  for {op, constant_result, operand} <- @ops_and_constant_results do
    defp walk({unquote(op), meta, [_lhs, unquote(operand)]} = ast, ctx) do
      {ast, put_issue(ctx, issue_for(ctx, meta, unquote(op), unquote(constant_result)))}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta, trigger, constant_result) do
    format_issue(
      ctx,
      message: "Operation will always return #{constant_result}.",
      trigger: trigger,
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
