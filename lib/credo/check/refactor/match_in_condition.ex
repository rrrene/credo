defmodule Credo.Check.Refactor.MatchInCondition do
  @moduledoc """
  Pattern matching should only ever be used for simple assignments
  inside `if` and `unless` clauses.

  While this fine:

      # okay, simple wildcard assignment:

      if contents = File.read!("foo.txt") do
        do_something
      end

  the following should be avoided, since it mixes a pattern match with a
  condition and do/else blocks.

      # considered too "complex":

      if {:ok, contents} = File.read("foo.txt") do
        do_something
      end

      # also considered "complex":

      if allowed? && ( contents = File.read!("foo.txt") ) do
        do_something
      end

  If you want to match for something and execute another block otherwise,
  consider using a `case` statement:

      case File.read("foo.txt") do
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
    defp traverse({unquote(op), _meta, arguments} = ast, issues, issue_meta) do
      condition_arguments =
        arguments
        |> Enum.reject(&Keyword.keyword?/1) # remove do/else blocks

      new_issues =
        Credo.Code.traverse(condition_arguments, &traverse_condition(&1, &2, unquote(op), condition_arguments, issue_meta))

      {ast, issues ++ new_issues}
    end
  end
  defp traverse(ast, issues, _source_file) do
    {ast, issues}
  end

  defp traverse_condition({:=, meta, arguments} = ast, issues, op, op_arguments, issue_meta) do
    case arguments do
      [{atom, _, nil}, _right] when is_atom(atom) ->
        # this means that the current ast is part of the `if/unless`
        if op_arguments |> Enum.member?(ast) do
          {ast, issues}
        else
          new_issue = issue_for(op, meta[:line], "=", issue_meta)
          {ast, issues ++ [new_issue]}
        end
      _ ->
        new_issue = issue_for(op, meta[:line], "=", issue_meta)
        {ast, issues ++ [new_issue]}
    end
  end
  defp traverse_condition(ast, issues, _op, _op_arguments, _issue_meta) do
    {ast, issues}
  end


  defp issue_for(op, line_no, trigger, issue_meta) do
    format_issue issue_meta,
      message: "There should be no matches in `#{op}` conditions.",
      trigger: trigger,
      line_no: line_no
  end
end
