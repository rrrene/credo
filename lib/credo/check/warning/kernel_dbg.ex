defmodule Credo.Check.Warning.KernelDbg do
  @moduledoc false

  use Credo.Check,
    base_priority: :high,
    explanations: [
      check: """
      While calls to dbg might appear in some parts of production code,
      most calls to this function are added during debugging sessions.

      This check warns about those calls, because they might have been committed
      in error.
      """
    ]

  @call_string "dbg"

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:dbg, _meta, nil} = ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp traverse({:dbg, meta, _arguments} = ast, issues, issue_meta) do
    {ast, issues_for_call(meta, issues, issue_meta)}
  end

  defp traverse(
         {{:., _, [{:__aliases__, _, [:"Elixir", :Kernel]}, :dbg]}, meta, _arguments} = ast,
         issues,
         issue_meta
       ) do
    {ast, issues_for_call(meta, issues, issue_meta)}
  end

  defp traverse(
         {{:., _, [{:__aliases__, _, [:Kernel]}, :dbg]}, meta, _arguments} = ast,
         issues,
         issue_meta
       ) do
    {ast, issues_for_call(meta, issues, issue_meta)}
  end

  defp traverse({:|>, _, [_, {:dbg, meta, nil}]} = ast, issues, issue_meta) do
    {ast, issues_for_call(meta, issues, issue_meta)}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issues_for_call(meta, issues, issue_meta) do
    [issue_for(issue_meta, meta[:line], @call_string) | issues]
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "There should be no calls to dbg/2.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
