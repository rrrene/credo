defmodule Credo.Check.Refactor.CondStatements do
  @moduledoc """
  Each cond statement should have 3 or more statements including the
  "always true" statement. Otherwise an `if` and `else` construct might be more
  appropriate.

  Example:

    cond do
      x == y -> 0
      true -> 1
    end

    # should be written as

    if x == y do
      0
    else
      1
    end

  """

  @explanation [check: @moduledoc]

  use Credo.Check

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:cond, meta, arguments} = ast, issues, issue_meta) do
    count =
      arguments
      |> CodeHelper.do_block_for!
      |> List.wrap
      |> Enum.count

    if count <= 2 do
      {ast, issues ++ [issue_for(issue_meta, meta[:line], :cond)]}
    else
      {ast, issues}
    end
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  def issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "Cond statements should contain at least two conditions besides `true`.",
      trigger: trigger,
      line_no: line_no
  end
end
