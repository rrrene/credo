defmodule Credo.Check.Refactor.MatchInCondition do
  @moduledoc """
  Pattern matching should not be used in `if` and `unless`.

  Example:

      if {:ok, value} = parameter1 do
        do_something
      end
  """

  @explanation [check: @moduledoc]

  @condition_ops [:if, :unless]

  use Credo.Check

  def run(%SourceFile{ast: ast} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.traverse(ast, &traverse(&1, &2, issue_meta))
  end

  for op <- @condition_ops do
    defp traverse({unquote(op), meta, arguments} = ast, issues, source_file) do
      new_issue =
        issue_for_first_condition(arguments |> List.first, unquote(op), meta, source_file)

      {ast, issues ++ List.wrap(new_issue)}
    end
  end
  defp traverse(ast, issues, _source_file) do
    {ast, issues}
  end

  defp issue_for_first_condition({:=, meta, _arguments}, op, meta, source_file) do
    issue_for(op, meta[:line], "=", source_file)
  end
  defp issue_for_first_condition(_, _, _, _), do: nil


  defp issue_for(op, line_no, trigger, source_file) do
    format_issue source_file,
      message: "There should be no matches in `#{op}` conditions.",
      trigger: trigger,
      line_no: line_no
  end
end
