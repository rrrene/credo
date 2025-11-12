defmodule Credo.Check.Refactor.MatchInCondition do
  use Credo.Check,
    id: "EX4016",
    param_defaults: [
      allow_tagged_tuples: false
    ],
    explanations: [
      check: """
      Pattern matching should only ever be used for simple assignments
      inside `if` and `unless` clauses.

      While this fine:

          # okay, simple wildcard assignment:

          if contents = File.read!("foo.txt") do
            do_something(contents)
          end

      the following should be avoided, since it mixes a pattern match with a
      condition and do/else blocks.

          # considered too "complex":

          if {:ok, contents} = File.read("foo.txt") do
            do_something(contents)
          end

          # also considered "complex":

          if allowed? && ( contents = File.read!("foo.txt") ) do
            do_something(contents)
          end

      If you want to match for something and execute another block otherwise,
      consider using a `case` statement:

          case File.read("foo.txt") do
            {:ok, contents} ->
              do_something()
            _ ->
              do_something_else()
          end

      """,
      params: [
        allow_tagged_tuples:
          "Allow tagged tuples in conditions, e.g. `if {:ok, contents} = File.read( \"foo.txt\") do`"
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    allow_tagged_tuples = Params.get(params, :allow_tagged_tuples, __MODULE__)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, allow_tagged_tuples, issue_meta))
  end

  defp traverse({op, _, nil} = ast, issues, _allow_tagged_tuples, _issue_meta)
       when op in [:if, :unless] do
    {ast, issues}
  end

  defp traverse({op, _, arguments} = ast, issues, allow_tagged_tuples, issue_meta)
       when op in [:if, :unless] do
    condition_head = Enum.reject(arguments, &Keyword.keyword?/1)

    new_issues =
      Credo.Code.prewalk(
        condition_head,
        &find_match(&1, &2, op, condition_head, allow_tagged_tuples, issue_meta)
      )

    {ast, issues ++ new_issues}
  end

  defp traverse(ast, issues, _allow_tagged_tuples, _source_file) do
    {ast, issues}
  end

  defp find_match(
         {:=, meta, [{var_name, _, nil}, rhs]} = ast,
         issues,
         op,
         op_arguments,
         _allow_tagged_tuples?,
         issue_meta
       )
       when is_atom(var_name) do
    assignment_in_body? = Enum.member?(op_arguments, ast)
    has_boolean_ops? = contains_boolean_operators?(rhs)

    if assignment_in_body? or has_boolean_ops? do
      if has_boolean_ops? do
        {ast, issues ++ [issue_for(op, meta[:line], issue_meta)]}
      else
        {ast, issues}
      end
    else
      {ast, issues ++ [issue_for(op, meta[:line], issue_meta)]}
    end
  end

  defp find_match(
         {:=, meta, [{tag_atom, {var_name, _, nil}}, _rhs]} = ast,
         issues,
         op,
         _op_args,
         allow_tagged_tuples?,
         issue_meta
       )
       when is_atom(var_name) and is_atom(tag_atom) do
    if allow_tagged_tuples? do
      {ast, issues}
    else
      new_issue = issue_for(op, meta[:line], issue_meta)

      {ast, issues ++ [new_issue]}
    end
  end

  defp find_match({:=, meta, _} = ast, issues, op, _op_args, _allow_tagged_tuples, issue_meta) do
    {ast, issues ++ [issue_for(op, meta[:line], issue_meta)]}
  end

  defp find_match(ast, issues, _op, _op_args, _allow_tagged_tuples, _issue_meta) do
    {ast, issues}
  end

  defp contains_boolean_operators?(ast) do
    case ast do
      {op, _, _} when op in [:&&, :||, :and, :or] -> true
      {_, _, args} when is_list(args) -> Enum.any?(args, &contains_boolean_operators?/1)
      _ -> false
    end
  end

  defp issue_for(op, line_no, issue_meta) do
    format_issue(
      issue_meta,
      message: "Avoid matches in `#{op}` conditions.",
      trigger: "=",
      line_no: line_no
    )
  end
end
