defmodule Credo.Check.Refactor.VariableRebinding do
  @explanation [
    check: @moduledoc
  ]

  @def_ops [:def, :defp, :defmacro]
  @nest_ops [:if, :unless, :case, :cond, :fn]

  alias Credo.Check.CodeHelper

  use Credo.Check

  def run(%SourceFile{ast: ast} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(ast, &traverse(&1, &2, issue_meta))
  end

  def traverse([do: {:__block__, _, ast}], issues, issue_meta) do
    variables = 
      ast
      |> Enum.map(&find_assignments/1)
      |> Enum.filter(&(&1 != nil))


    duplicates = 
      variables
      |> Enum.filter(fn {key, _} ->
        Enum.count(variables, fn 
          {other, _} -> key == other
        end) >= 2
      end)
      |> Enum.uniq_by(fn 
        {v, _} -> v
      end)

    new_issues = 
      duplicates
      |> Enum.map(fn {variable_name, line} ->
        issue_for(issue_meta, Atom.to_string(variable_name), line)
      end)

    if length(new_issues) > 0 do
      {ast, issues ++ new_issues}
    else
      {ast, issues}
    end
  end
  
  def traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp find_assignments({:=, meta, [{variable_name, _, _}, _]}) do
    {variable_name, meta[:line]}
  end
  
  defp find_assignments(_), do: nil

  defp issue_for(issue_meta, trigger, line) do
    format_issue issue_meta,
      message: "Variable was declared more than once.",
      trigger: trigger,
      line_no: line
  end
end