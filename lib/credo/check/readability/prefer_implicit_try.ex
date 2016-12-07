defmodule Credo.Check.Readability.PreferImplicitTry do
  @moduledoc """
We don't need to explicity use `try` in function definitions. For example, this:

defmodule ModuleWithRescue do
  def failing_function(first) do
    try do
      to_string(first)
    rescue
      _ -> :rescued
    end
  end
end

Could be rewritten without `try` as below:

defmodule ModuleWithRescue do
  def failing_function(first) do
    to_string(first)
  rescue
    _ -> :rescued
  end
end
"""

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :low

  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:def, _, [{_, _, _}, [do: {:try, [line: line_no], _}]]} = ast, issues, issue_meta) do
    {ast, issues ++ [issue_for(issue_meta, line_no)]}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no) do
    format_issue issue_meta,
      message: "Prefer using an implicit `try` rather than explicit `try`",
      trigger: "try",
      line_no: line_no
  end
end
