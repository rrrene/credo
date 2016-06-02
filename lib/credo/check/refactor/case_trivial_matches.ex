defmodule Credo.Check.Refactor.CaseTrivialMatches do
  @moduledoc """
  PLEASE NOTE: This check is deprecated as it might do more harm than good.

  Related discussion: https://github.com/rrrene/credo/issues/65
  """

  @explanation [check: @moduledoc]

  use Credo.Check

  def run(%SourceFile{ast: ast} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.traverse(ast, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:case, meta, arguments} = ast, issues, issue_meta) do
    cases =
      arguments
      |> CodeHelper.do_block_for!
      |> List.wrap
      |> Enum.map(&case_statement_for/1)
      |> Enum.sort

    if cases == [false, true] do
      {ast, issues ++ [issue_for(issue_meta, meta[:line], :cond)]}
    else
      {ast, issues}
    end
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp case_statement_for({:->, _, [[true], _]}), do: true
  defp case_statement_for({:->, _, [[false], _]}), do: false
  defp case_statement_for(_), do: nil

  def issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "Case statements should not only contain `true` and `false`.",
      trigger: trigger,
      line_no: line_no
  end
end
