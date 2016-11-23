defmodule Credo.Check.Refactor.SinglePipe do
  @moduledoc """
    "The pipe was designed to express pipelines and you don't have a pipeline if you have only one call"
    So instead of foo |> bar, just use foo(bar)
  """

  @explanation [check: @moduledoc]

  use Credo.Check

  def run(%SourceFile{ast: ast} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    {_continue, issues} = Credo.Code.prewalk(ast, &traverse(&1, &2, issue_meta), {true, []})
    issues
  end

  defp traverse({:|>, _, [{:|>, _, _} | _]} = ast, {_, issues} = state, issue_meta) do
    {ast, {false, issues}}
  end

  defp traverse({:|>, meta, _} = ast, {true, issues}, issue_meta) do    
    {ast, {false, issues ++ [issue_for(issue_meta, meta[:line], "single pipe")]}}
  end
  
  defp traverse(ast, {_, issues}, _issue_meta) do    
    {ast, {true, issues}}
  end

  def issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "There's no reason to use a single pipe character. Replace with a simple function call",
      trigger: trigger,
      line_no: line_no
  end
end
