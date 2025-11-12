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

    source_file
    |> Credo.Code.to_tokens()
    |> collect_issues([], ctx)
  end

  defp collect_issues([], acc, _ctx), do: acc

  defp collect_issues([{:";", {line_no, column1, _}} | rest], acc, ctx) do
    acc = [issue_for(ctx, line_no, column1) | acc]
    collect_issues(rest, acc, ctx)
  end

  defp collect_issues([_ | rest], acc, ctx), do: collect_issues(rest, acc, ctx)

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
