defmodule Credo.Check.Warning.LazyLogging do
  @moduledoc """
  Ensures laziness of Logger calls.
  The best practice is to wrap an expensive logger calls into a zero argument function (fn -> "input" end)
  Example:
    Logger.info fn -> "expensive to calculate info" end
  Instead of:
      Logger.info "mission accomplished"

  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high

  @doc false
  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    state = {false, []} # Logger import seen ?, list of issues
    {_, issues} = Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta), state)
    issues
  end

  defp traverse({{:., _, [{:__aliases__, _, [:Logger]}, _]}, meta, arguments} = ast, state, issue_meta) do
    {ast, issues_for_call(arguments, meta, state, issue_meta)}
  end
  defp traverse({:debug, meta, arguments} = ast, {true, _issues} = state, issue_meta) do
    {ast, issues_for_call(arguments, meta, state, issue_meta)}
  end
  defp traverse({:info, meta, arguments} = ast, {true, _issues} = state, issue_meta) do
    {ast, issues_for_call(arguments, meta, state, issue_meta)}
  end
  defp traverse({:warn, meta, arguments} = ast, {true, _issues} = state, issue_meta) do
    {ast, issues_for_call(arguments, meta, state, issue_meta)}
  end
  defp traverse({:error, meta, arguments} = ast, {true, _issues} = state, issue_meta) do
    {ast, issues_for_call(arguments, meta, state, issue_meta)}
  end
  defp traverse({:import, _meta, arguments} = ast, state, _issue_meta) do
     if logger_import?(arguments) do
        {_, issue_list} = state
        {ast, {true, issue_list}}
     else
        {ast, state}
     end
  end
  defp traverse(ast, state, _issue_meta) do
    {ast, state}
  end

  defp issues_for_call([{:<<>>, _, [_ | _]} | _] = _args, meta, {import?, issues}, issue_meta) do
      {import?, [issue_for(issue_meta, meta[:line]) | issues]}
  end
  defp issues_for_call(_args, _meta, state, _issue_meta) do
    state
  end

  defp issue_for(issue_meta, line_no) do
    format_issue issue_meta,
      message: "Logger usage is not lazzy",
      line_no: line_no
  end

  defp logger_import?([{:__aliases__, _meta, [:Logger]}]) do
    true
  end
  defp logger_import?(_ast) do
    false
  end

end
