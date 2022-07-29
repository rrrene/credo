defmodule Credo.Check.Readability.WithSingleClause do
  use Credo.Check,
    explanations: [
      check: ~S"""
      `with` statements are useful when you need to chain a sequence
      of pattern matches, stopping at the first one that fails.

      If the `with` has a single pattern matching clause and no `else`
      branch, it means that if the clause doesn't match than the whole
      `with` will return the value of that clause.

      However, if that `with` has also an `else` clause, then you're using `with` exactly
      like a `case` and a `case` should be used instead.

      Take this code:

          with {:ok, user} <- User.create(make_ref()) do
            user
          else
            {:error, :db_down} ->
              raise "DB is down!"

            {:error, reason} ->
              raise "error: #{inspect(reason)}"
          end

      It can be rewritten with a clearer use of `case`:

          case User.create(make_ref()) do
            {:ok, user} ->
              user

            {:error, :db_down} ->
              raise "DB is down!"

            {:error, reason} ->
              raise "error: #{inspect(reason)}"
          end

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # TODO: consider for experimental check front-loader (ast)
  defp traverse({:with, meta, [_, _ | _] = clauses_and_body} = ast, issues, issue_meta)
       when is_list(clauses_and_body) do
    # If clauses_and_body is a list with at least two elements in it, we think
    # this might be a call to the special form "with". To be sure of that,
    # we get the last element of clauses_and_body and check that it's a keyword
    # list with a :do key in it (the body).

    # We can hard-match on [maybe_body] here since we know that clauses_and_body
    # has at least two elements.
    {maybe_clauses, [maybe_body]} = Enum.split(clauses_and_body, -1)

    if Keyword.keyword?(maybe_body) and Keyword.has_key?(maybe_body, :do) do
      issue =
        issue_if_one_pattern_clause_with_else(maybe_clauses, maybe_body, meta[:line], issue_meta)

      {ast, issue ++ issues}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_if_one_pattern_clause_with_else(clauses, body, line, issue_meta) do
    contains_unquote_splicing? = Enum.any?(clauses, &match?({:unquote_splicing, _, _}, &1))
    pattern_clauses_count = Enum.count(clauses, &match?({:<-, _, _}, &1))

    cond do
      contains_unquote_splicing? ->
        []

      pattern_clauses_count <= 1 and Keyword.has_key?(body, :else) ->
        [
          format_issue(issue_meta,
            message:
              "`with` contains only one <- clause and an `else` branch, consider using `case` instead",
            line_no: line
          )
        ]

      true ->
        []
    end
  end
end
