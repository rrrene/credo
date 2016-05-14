defmodule Credo.Check.Refactor.MatchInCondition do
  @moduledoc """
  Pattern matching should only ever be used for simple assignments
  inside `if` and `unless` clauses.

  While this fine:

      if contents = File.read!("foo.txt") do
        do_something
      end

  the following should be avoided, since it mixes a pattern match with a
  condition and do/else blocks.

      if {:ok, contents} = File.read("foo.txt") do
        do_something
      end

  If you want to match for something and execute another block otherwise,
  consider using a `case` statement:

      case  = File.read("foo.txt") do
        {:ok, contents} -> do_something
        _ -> do_something_else
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

  defp issue_for_first_condition({:=, meta, arguments}, op, meta, source_file) do
    case arguments do
      [{atom, _, nil}, _right] when is_atom(atom) ->
        nil
      _ ->
        issue_for(op, meta[:line], "=", source_file)
    end
  end
  defp issue_for_first_condition(_, _, _, _), do: nil


  defp issue_for(op, line_no, trigger, source_file) do
    format_issue source_file,
      message: "There should be no matches in `#{op}` conditions.",
      trigger: trigger,
      line_no: line_no
  end
end
