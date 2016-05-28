defmodule Credo.Check.Warning.BoolOperationOnSameValues do
  @moduledoc """
  Boolean operation on the same values is most probably a logic or a copy-paste error.

  Examples:
      # right side of these expressions is useless
      x && x
      x || x
      x and x
      x or x
  """

  @explanation [check: @moduledoc]
  @ops [:and, :or, :&&, :||]

  use Credo.Check, base_priority: :high

  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.traverse(source_file, &traverse(&1, &2, issue_meta))
  end

  for op <- @ops do
    defp traverse({unquote(op), meta, [lhs, rhs]} = ast, issues, issue_meta) do
      if lhs == rhs do
        new_issue = issue_for(issue_meta, meta[:line], unquote(op))
        {ast, issues ++ [new_issue]}
      else
        {ast, issues}
      end
    end
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end


  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "There are identical sub-expressions to the left and to the right of the '#{trigger}' operator.",
      trigger: trigger,
      line_no: line_no
  end
end
