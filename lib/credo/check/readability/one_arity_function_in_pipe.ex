defmodule Credo.Check.Readability.OneArityFunctionInPipe do
  use Credo.Check,
    base_priority: :low,
    explanations: [
      check: """
      Use parentheses for one-arity functions when using the pipe operator (|>).

          # not preferred
          some_string |> String.downcase |> String.trim

          # preferred
          some_string |> String.downcase() |> String.trim()
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    Credo.Code.prewalk(source_file, &traverse(&1, &2, IssueMeta.for(source_file, params)))
  end

  defp traverse(ast, issues, issue_meta) do
    case issue(ast, issue_meta) do
      nil -> {ast, issues}
      issue -> {ast, [issue | issues]}
    end
  end

  defp issue({:|>, _meta, [_left, {name, meta, nil}]}, issue_meta) when is_atom(name) do
    format_issue(
      issue_meta,
      message: "One arity functions should have parentheses in pipes",
      line_no: meta[:line]
    )
  end

  defp issue(_ast, _issue_meta), do: nil
end
