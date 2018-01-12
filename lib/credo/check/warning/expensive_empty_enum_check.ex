defmodule Credo.Check.Warning.ExpensiveEmptyEnumCheck do
  @moduledoc """
  Checking if the size of the enum is `0` can be very expensive, since you are
  determining the exact count of elements.

  Checking if an enum is empty should be done by using

    Enum.empty?(enum)

  or

    list == []

  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  @enum_count_pattern quote do: {
                              {:., _, [{:__aliases__, _, [:Enum]}, :count]},
                              _,
                              _
                            }
  @length_pattern quote do: {:length, _, _}
  @comparisons [
    {@enum_count_pattern, 0},
    {0, @enum_count_pattern},
    {@length_pattern, 0},
    {0, @length_pattern}
  ]

  for {lhs, rhs} <- @comparisons do
    defp traverse(
           {:==, meta, [unquote(lhs), unquote(rhs)]} = ast,
           issues,
           issue_meta
         ) do
      {ast, issues_for_call(meta, issues, issue_meta, ast)}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  def issues_for_call(meta, issues, issue_meta, ast) do
    [issue_for(issue_meta, meta[:line], Macro.to_string(ast)) | issues]
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "#{trigger} is expensive. Prefer Enum.empty?/1 or list == []",
      trigger: trigger,
      line_no: line_no
    )
  end
end
