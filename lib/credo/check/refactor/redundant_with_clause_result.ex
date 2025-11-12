defmodule Credo.Check.Refactor.RedundantWithClauseResult do
  use Credo.Check,
    id: "EX4024",
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

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:with, meta, clauses_and_body} = ast, ctx) do
    case split(clauses_and_body) do
      {:ok, clauses, body} ->
        case issue_for({clauses, body}, meta, ctx) do
          nil -> {ast, ctx}
          issue -> {ast, put_issue(ctx, issue)}
        end

      :error ->
        {ast, ctx}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
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

  defp issue_for({clauses, body}, meta, ctx) do
    case {redundant?(List.last(clauses), body), length(clauses)} do
      {true, 1} ->
        format_issue(ctx,
          message: "`with` statement is redundant.",
          line_no: meta[:line],
          trigger: "with"
        )

      {true, _length} ->
        format_issue(ctx,
          message: "Last clause in `with` is redundant.",
          line_no: meta[:line],
          trigger: "with"
        )

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
