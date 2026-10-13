defmodule Credo.Check.Readability.Semicolons do
  use Credo.Check,
    id: "EX3020",
    base_priority: :high,
    tags: [:formatter],
    explanations: [
      check: """
      Don't use ; to separate statements and expressions.
      Statements and expressions should be separated by lines.

          # preferred

          a = 1
          b = 2

          # NOT preferred

          a = 1; b = 2

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    ctx = Credo.Code.Token.reduce(source_file, &handle_reduce/4, ctx)
    ctx.issues
  end

  defp handle_reduce(_prev, {{:";", _}, {line_no, column, _, _}, _, _}, _next, ctx) do
    put_issue(ctx, issue_for(ctx, line_no, column))
  end

  defp handle_reduce(_prev, _current, _next, ctx), do: ctx

  defp issue_for(ctx, line_no, column) do
    format_issue(
      ctx,
      message: "Don't use `;` to separate statements and expressions.",
      line_no: line_no,
      column: column,
      trigger: ";"
    )
  end
end
