defmodule Credo.Check.Refactor.CondStatements do
  use Credo.Check,
    explanations: [
      check: """
      Each cond statement should have 3 or more statements including the
      "always true" statement.

      Consider an `if`/`else` construct if there is only one condition and the
      "always true" statement, since it will more accessible to programmers
      new to the codebase (and possibly new to Elixir).

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
    ]

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:cond, meta, arguments} = ast, issues, issue_meta) do
    count =
      arguments
      |> Credo.Code.Block.do_block_for!()
      |> List.wrap()
      |> Enum.count()

    if count <= 2 do
      {ast, issues ++ [issue_for(issue_meta, meta[:line], :cond)]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message:
        "Cond statements should contain at least two conditions besides `true`, consider using `if` instead.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
