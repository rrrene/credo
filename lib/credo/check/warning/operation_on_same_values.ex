defmodule Credo.Check.Warning.OperationOnSameValues do
  @moduledoc """
  Operations on the same values always yield the same result and therefore make
  little sense in production code.

  Examples:

      x == x  # always returns true
      x <= x  # always returns true
      x >= x  # always returns true
      x != x  # always returns false
      x > x   # always returns false
      y / y   # always returns 1
      y - y   # always returns 0

  In practice they are likely the result of a debugging session or were made by
  mistake.
  """

  @explanation [check: @moduledoc]
  @ops_and_constant_results [
      {:==, "Comparison", true},
      {:>=, "Comparison", true},
      {:<=, "Comparison", true},
      {:!=, "Comparison", false},
      {:>, "Comparison", false},
      {:<, "Comparison", false},
      {:/, "Operation", 1},
      {:-, "Operation", 0}
    ]

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  for {op, operation_name, constant_result} <- @ops_and_constant_results do
    defp traverse({unquote(op), meta, [lhs, rhs]} = ast, issues, issue_meta) do
      if CodeHelper.remove_metadata(lhs) == CodeHelper.remove_metadata(rhs) do
        new_issue =
          issue_for(issue_meta, meta[:line], unquote(op),
            unquote(operation_name), unquote(constant_result))

        {ast, issues ++ [new_issue]}
      else
        {ast, issues}
      end
    end
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end


  defp issue_for(issue_meta, line_no, trigger, operation, constant_result) do
    format_issue issue_meta,
      message: "#{operation} will always return #{constant_result}.",
      trigger: trigger,
      line_no: line_no
  end
end
