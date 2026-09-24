defmodule Credo.Check.Readability.OneArityFunctionInPipe do
  use Credo.Check,
    id: "EX3034",
    base_priority: :low,
    explanations: [
      check: """
      Use parentheses for one-arity functions when using the pipe operator (|>).

          # not preferred
          some_string |> String.downcase |> String.trim

          # preferred
          some_string |> String.downcase() |> String.trim()

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ],
    managed_traversal: :ast

  def handle_walk({:|>, _, [_, {name, meta, nil}]} = ast, ctx) when is_atom(name) do
    {ast, put_issue(ctx, issue_for(ctx, meta, name))}
  end

  def handle_walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta, name) do
    format_issue(
      ctx,
      message: "One arity functions should have parentheses in pipes.",
      trigger: name,
      line_no: meta[:line]
    )
  end
end
