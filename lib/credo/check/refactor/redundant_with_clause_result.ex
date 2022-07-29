defmodule Credo.Check.Refactor.RedundantWithClauseResult do
  use Credo.Check,
    base_priority: :high,
    explanations: [
      check: ~S"""
      `with` statements are useful when you need to chain a sequence
      of pattern matches, stopping at the first one that fails.

      If the match of the last clause in a `with` statement is identical to the expression in the
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

  alias Credo.Code.Block

  require Logger

  @redundant_with "the `with` statement is redundant"
  @redundant_clause "the last clause in `with` is redundant"

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:with, meta, clauses_and_body} = ast, issues, issue_meta) do
    case split(clauses_and_body) do
      {:ok, clauses, body} ->
        case issue_for({clauses, body}, meta, issue_meta) do
          nil -> {ast, issues}
          issue -> {ast, [issue | issues]}
        end

      :error ->
        {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp split(clauses_and_body) do
    case Block.do_block?(clauses_and_body) and not Block.else_block?(clauses_and_body) do
      false ->
        :error

      true ->
        {clauses, [body]} = Enum.split(clauses_and_body, -1)
        {:ok, clauses, Keyword.get(body, :do)}
    end
  end

  defp issue_for({clauses, body}, meta, issue_meta) do
    case {redundant?(List.last(clauses), body), length(clauses)} do
      {true, 1} ->
        format_issue(issue_meta, message: @redundant_with, line_no: meta[:line])

      {true, _length} ->
        format_issue(issue_meta, message: @redundant_clause, line_no: meta[:line])

      _else ->
        nil
    end
  end

  defp redundant?({:<-, _meta, [body, _expr]}, body), do: true

  defp redundant?({:<-, _meta, [match, _expr]}, body) do
    Credo.Code.remove_metadata(match) == Credo.Code.remove_metadata(body)
  end

  defp redundant?(_last_clause, _body), do: false
end
