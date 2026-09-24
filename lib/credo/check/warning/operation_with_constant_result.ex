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
    ],
    managed_traversal: :ast

  @ops_and_constant_results [
    {:*, "zero", 0},
    {:*, "the left side of the expression", 1}
  ]

  # skip references to functions
  def handle_walk({:&, _, _}, ctx) do
    {nil, ctx}
  end

  # skip specs
  def handle_walk({:@, _, [{:spec, _, _}]}, ctx) do
    {nil, ctx}
  end

  for {op, constant_result, operand} <- @ops_and_constant_results do
    def handle_walk({unquote(op), meta, [_lhs, unquote(operand)]} = ast, ctx) do
      {ast, put_issue(ctx, issue_for(ctx, meta, unquote(op), unquote(constant_result)))}
    end
  end

  def handle_walk(ast, ctx) do
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
