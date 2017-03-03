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
    state = {false, []} # Logger seen ?, list of issues
    {_, issues} = Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta), state)
    issues
  end

  defp traverse({{:., _, [{:__aliases__, _, [:Logger]}, _]}, meta, arguments} = ast, issues, issue_meta) do
    {ast, issues_for_call(arguments, meta, issues, issue_meta, logger_call: true)}
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
  defp traverse({:import, _meta, arguments} = ast, issues, _issue_meta) do
     if logger_import?(arguments) do
        {_, issue_list} = issues
        {ast, {true, issue_list}}
     else
        {ast, issues}
     end
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issues_for_call([{:fn, _, __}] = _args, _meta, issues, _issue_meta, _) do
    issues
  end
  defp issues_for_call(args, meta, {true, issues}, issue_meta) do
    #  arity check
    case Enum.count(args) do
        1 ->
            {true, [issue_for(issue_meta, meta[:line]) | issues]}
        _ ->
            {true, issues}
    end
  end
  defp issues_for_call(_args, meta, {import?, issues}, issue_meta, logger_call: true) do
    {import?, [issue_for(issue_meta, meta[:line]) | issues]}
  end
  defp issues_for_call(_args, _meta, issues, _issue_meta) do
    issues
  end

  defp issue_for(issue_meta, line_no) do
    format_issue issue_meta,
      message: "Logger call is not lazzy",
      line_no: line_no
  end

  defp logger_import?([{:__aliases__, _meta, [:Logger]}]) do
    true
  end
  defp logger_import?(_ast) do
    false
  end

end
