defmodule Credo.Check.Warning.Dbg do
  use Credo.Check,
    id: "EX5026",
    base_priority: :high,
    elixir_version: ">= 1.14.0-dev",
    explanations: [
      check: """
      Calls to dbg/0 and dbg/2 should mostly be used during debugging sessions.

      This check warns about those calls, because they probably have been committed
      in error.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse(
         {:@, _, [{:dbg, _, _}]},
         issues,
         _issue_meta
       ) do
    {nil, issues}
  end

  defp traverse(
         {:dbg, meta, []} = ast,
         issues,
         issue_meta
       ) do
    {ast, [issue_for(issue_meta, meta, "dbg") | issues]}
  end

  defp traverse(
         {:dbg, meta, [_single_param]} = ast,
         issues,
         issue_meta
       ) do
    {ast, [issue_for(issue_meta, meta, "dbg") | issues]}
  end

  defp traverse(
         {:dbg, meta, [_first_param, _second_param]} = ast,
         issues,
         issue_meta
       ) do
    {ast, [issue_for(issue_meta, meta, "dbg") | issues]}
  end

  defp traverse(
         {{:., _, [{:__aliases__, meta, [:"Elixir", :Kernel]}, :dbg]}, _, _args} = ast,
         issues,
         issue_meta
       ) do
    {ast, [issue_for(issue_meta, meta, "Elixir.Kernel.dbg") | issues]}
  end

  defp traverse(
         {{:., _, [{:__aliases__, meta, [:Kernel]}, :dbg]}, _, _args} = ast,
         issues,
         issue_meta
       ) do
    {ast, [issue_for(issue_meta, meta, "Kernel.dbg") | issues]}
  end

  defp traverse(
         {:|>, _, [_, {:dbg, meta, nil}]} = ast,
         issues,
         issue_meta
       ) do
    {ast, [issue_for(issue_meta, meta, "dbg") | issues]}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, meta, trigger) do
    format_issue(
      issue_meta,
      message: "There should be no calls to `dbg/1`.",
      trigger: trigger,
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
