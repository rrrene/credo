defmodule Credo.Check.Refactor.WithClauses do
  @moduledoc false

  @checkdoc ~S"""
  `with` statements are useful when you need to chain a sequence
  of pattern matches, stopping at the first one that fails.

  However, there are a few cases where a `with` can be used incorrectly.

  ## Starting or ending with non-pattern-matching clauses

  If the `with` starts or ends with clauses that are not `<-` clauses,
  then those clauses should be moved either outside of the `with` (if
  they're the first ones) or inside the body of the `with` (if they're the
  last ones). For example look at this code:

      with ref = make_ref(),
           {:ok, user} <- User.create(ref),
           Logger.debug("Created user: #{inspect(user)}") do
        user
      end

  This `with` should be refactored like this:

      ref = make_ref()

      with {:ok, user} <- User.create(ref) do
        Logger.debug("Created user: #{inspect(user)}")
        user
      end

  # Using only one pattern matching clause with `else`

  If the `with` has a single pattern matching clause and no `else`
  branch, it means that if the clause doesn't match than the whole
  `with` will return the value of that clause. However, if that
  `with` has also an `else` clause, then you're using `with` exactly
  like a `case` and a `case` should be used instead. Take this code:

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

  @explanation [
    check: @checkdoc,
    params: []
  ]

  @message_only_one_pattern_clause "\"with\" contains only one <- clause and an \"else\" " <>
                                     "branch, use a \"case\" instead"
  @message_first_clause_not_pattern "\"with\" doesn't start with a <- clause, " <>
                                      "move the non-pattern <- clauses outside of the \"with\""
  @message_last_clause_not_pattern "\"with\" doesn't end with a <- clause, move " <>
                                     "the non-pattern <- clauses inside the body of the \"with\""

  use Credo.Check, base_priority: :high, category: :refactor, exit_status: 1

  alias Credo.Code

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:with, meta, clauses} = ast, issues, issue_meta) do
    {ast, issues_for_with(clauses, meta[:line], issue_meta) ++ issues}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issues_for_with(clauses, line, issue_meta) do
    clauses_without_body = Enum.drop(clauses, -1)

    issue_if_one_pattern_clause(clauses, line, issue_meta) ++
      issue_if_not_starting_with_pattern_clause(clauses_without_body, line, issue_meta) ++
      issue_if_not_ending_with_pattern_clause(clauses_without_body, line, issue_meta)
  end

  defp issue_if_one_pattern_clause(clauses, line, issue_meta) do
    {clauses, body} = Enum.split(clauses, -1)
    pattern_clauses_count = Enum.count(clauses, &match?({:<-, _, _}, &1))
    else? = body != [] and Keyword.has_key?(List.first(body), :else)

    if pattern_clauses_count <= 1 and else? do
      [format_issue(issue_meta, message: @message_only_one_pattern_clause, line_no: line)]
    else
      []
    end
  end

  defp issue_if_not_starting_with_pattern_clause(
         [{:<-, _meta, _args} | _rest],
         _line,
         _issue_meta
       ) do
    []
  end

  defp issue_if_not_starting_with_pattern_clause(_clauses, line, issue_meta) do
    [format_issue(issue_meta, message: @message_first_clause_not_pattern, line_no: line)]
  end

  defp issue_if_not_ending_with_pattern_clause(clauses, line, issue_meta) do
    if length(clauses) > 1 and not match?({:<-, _, _}, Enum.at(clauses, -1)) do
      [format_issue(issue_meta, message: @message_last_clause_not_pattern, line_no: line)]
    else
      []
    end
  end
end
