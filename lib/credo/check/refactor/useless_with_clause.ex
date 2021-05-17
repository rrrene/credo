defmodule Credo.Check.Refactor.UselessWithClause do
  use Credo.Check,
    base_priority: :high,
    explanations: [
      check: ~S"""
      `with` statements are useful when you need to chain a sequence
      of pattern matches, stopping at the first one that fails.

      If the `match` of the last clause in a with equal to the expression in the
      in its body, the code should be refactored to remove the redundant expression.

      This should be refactored:

          with {:ok, map} <- check(input),
               {:ok, result} <- something(map) do
            {:ok, result}
          end

      to look like this:

          with {:ok, map} <- check(input) do
            something(map)
          end
      """
    ]

  alias Credo.Code

  require Logger

  @useless_with "the `with` statement is useless"
  @useless_clause "the last clause in `with` is useless"

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

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
      {ast,
       issues_for(
         {maybe_clauses, Keyword.get(maybe_body, :do)},
         meta[:line],
         issue_meta
       ) ++ issues}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issues_for({clauses, body}, line, issue_meta) do
    last_clause = List.last(clauses)

    case {useless?(last_clause, body), length(clauses)} do
      {true, 1} ->
        [format_issue(issue_meta, message: @useless_with, line_no: line)]

      {true, _length} ->
        [format_issue(issue_meta, message: @useless_clause, line_no: line)]

      _else ->
        []
    end
  end

  defp useless?({:<-, _meta, [body, _expr]}, body), do: true

  defp useless?({:<-, _meta, [match, _expr]}, body) do
    Code.remove_metadata(match) == Code.remove_metadata(body)
  end

  defp useless?(_last_clause, _body), do: false
end
