defmodule Credo.Check.Warning.LazyLogging do
  @moduledoc """
  Ensures laiziness of Logger calls.
  The best practice is to wrap an expensive logger expression into a zero argument function (fn -> "input" end)
  Example:
    Logger.debug fn ->
        "my_fun/1: input: #{inspect :expensive_to_compute}"
    end
  Instead of:
    Logger.debug "my_fun/1: input: #{inspect :expensive_to_compute}"

  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high

  @doc false
  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({{:., _, [{:__aliases__, _, [:Logger]}, _]}, meta, arguments} = ast, issues, issue_meta) do
    {ast, issues_for_call(arguments, meta, issues, issue_meta)}
  end
  defp traverse({:debug, meta, arguments} = ast, issues, issue_meta) do
    {ast, issues_for_call(arguments, meta, issues, issue_meta)}
  end
  defp traverse({:info, meta, arguments} = ast, issues, issue_meta) do
    {ast, issues_for_call(arguments, meta, issues, issue_meta)}
  end
  defp traverse({:warn, meta, arguments} = ast, issues, issue_meta) do
    {ast, issues_for_call(arguments, meta, issues, issue_meta)}
  end
  defp traverse({:error, meta, arguments} = ast, issues, issue_meta) do
    {ast, issues_for_call(arguments, meta, issues, issue_meta)}
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  def issues_for_call([{:fn, _, __}] = _args, _meta, issues, _issue_meta) do
    issues
  end
  def issues_for_call(_args, meta, issues, issue_meta) do
    [issue_for(issue_meta, meta[:line]) | issues]
  end

  defp issue_for(issue_meta, line_no) do
    format_issue issue_meta,
      message: "Logger input is not lazzy",
      line_no: line_no
  end
end
