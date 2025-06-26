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
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    Credo.Code.prewalk(source_file, &traverse(&1, &2, IssueMeta.for(source_file, params)))
  end

  defp traverse({:|>, _, [_, {name, meta, nil}]} = ast, issues, issue_meta) when is_atom(name) do
    {ast, [issue_for(issue_meta, meta[:line], name) | issues]}
  end

  defp traverse(ast, issues, _) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line, name) do
    format_issue(
      issue_meta,
      message: "One arity functions should have parentheses in pipes.",
      line_no: line,
      trigger: name
    )
  end
end
