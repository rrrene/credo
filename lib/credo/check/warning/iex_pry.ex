defmodule Credo.Check.Warning.IExPry do
  @moduledoc """
  While calls to IEx.pry might appear in some parts of production code,
  most calls to this function are added during debugging sessions.

  This check warns about those calls, because they might have been committed
  in error.
  """

  @explanation [check: @moduledoc]
  @call_string "IEx.pry"

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({{:., _, [{:__aliases__, _, [:IEx]}, :pry]}, meta, _arguments} = ast, issues, issue_meta) do
    {ast, issues_for_call(meta, issues, issue_meta)}
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  def issues_for_call(meta, issues, issue_meta) do
    [issue_for(issue_meta, meta[:line], @call_string) | issues]
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "There should be no calls to IEx.pry/1.",
      trigger: trigger,
      line_no: line_no
  end
end
