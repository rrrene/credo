defmodule Credo.Check.Refactor.MatchInCondition do
  use Credo.Check,
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

  @condition_ops [:if, :unless]
  @trigger "="

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    allow_tagged_tuples = Params.get(params, :allow_tagged_tuples, __MODULE__)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, allow_tagged_tuples, issue_meta))
  end

  # Skip if arguments is not enumerable
  defp traverse({_op, _meta, nil} = ast, issues, _allow_tagged_tuples, _source_file) do
    {ast, issues}
  end

  # TODO: consider for experimental check front-loader (ast)
  # NOTE: we have to exclude the cases matching the above
  for op <- @condition_ops do
    defp traverse({unquote(op), _meta, arguments} = ast, issues, allow_tagged_tuples, issue_meta) do
      # remove do/else blocks
      condition_arguments = Enum.reject(arguments, &Keyword.keyword?/1)

      new_issues =
        Credo.Code.prewalk(
          condition_arguments,
          &traverse_condition(
            &1,
            &2,
            unquote(op),
            condition_arguments,
            allow_tagged_tuples,
            issue_meta
          )
        )

      {ast, issues ++ new_issues}
    end
  end

  defp traverse(ast, issues, _allow_tagged_tuples, _source_file) do
    {ast, issues}
  end

  defp traverse_condition(
         {:=, meta, arguments} = ast,
         issues,
         op,
         op_arguments,
         allow_tagged_tuples?,
         issue_meta
       ) do
    assignment_in_body? = Enum.member?(op_arguments, ast)

    case arguments do
      [{atom, _, nil}, _right] when is_atom(atom) ->
        if assignment_in_body? do
          {ast, issues}
        else
          new_issue = issue_for(op, meta[:line], issue_meta)

          {ast, issues ++ [new_issue]}
        end

      [{tag_atom, {atom, _, nil}}, _right] when is_atom(atom) and is_atom(tag_atom) ->
        if allow_tagged_tuples? do
          {ast, issues}
        else
          new_issue = issue_for(op, meta[:line], issue_meta)

          {ast, issues ++ [new_issue]}
        end

      _ ->
        new_issue = issue_for(op, meta[:line], issue_meta)
        {ast, issues ++ [new_issue]}
    end
  end

  defp traverse_condition(ast, issues, _op, _op_arguments, _allow_tagged_tuples, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(op, line_no, issue_meta) do
    format_issue(
      issue_meta,
      message: "There should be no matches in `#{op}` conditions.",
      trigger: @trigger,
      line_no: line_no
    )
  end
end
