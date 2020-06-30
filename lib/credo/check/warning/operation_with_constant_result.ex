defmodule Credo.Check.Warning.OperationWithConstantResult do
  use Credo.Check,
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
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # skip references to functions
  defp traverse({:&, _, _}, issues, _) do
    {nil, issues}
  end

  for {op, constant_result, operand} <- @ops_and_constant_results do
    defp traverse(
           {unquote(op), meta, [_lhs, unquote(operand)]} = ast,
           issues,
           issue_meta
         ) do
      new_issue =
        issue_for(
          issue_meta,
          meta[:line],
          unquote(op),
          unquote(constant_result)
        )

      {ast, issues ++ [new_issue]}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, trigger, constant_result) do
    format_issue(
      issue_meta,
      message: "Operation will always return #{constant_result}.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
