defmodule Credo.Check.Readability.OnePipePerLine do
  use Credo.Check,
    id: "EX3035",
    category: :readability,
    explanations: [
      check: """
      Don't use multiple pipes (|>) in the same line.
      Each function in the pipe should be in it's own line.

          # preferred

          foo
          |> bar()
          |> baz()

          # NOT preferred

          foo |> bar() |> baz()

      The code in this example ...

          1 |> Integer.to_string() |> String.to_integer()

      ... should be refactored to look like this:

          1
          |> Integer.to_string()
          |> String.to_integer()

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.prewalk(&traverse/2)
    |> Enum.uniq()
    |> Enum.map(&issue_for(issue_meta, &1))
  end

  defp traverse({:|>, meta, [{:|>, meta2, _} | _]} = ast, acc) do
    if meta[:line] == meta2[:line] do
      {ast, [meta[:line] | acc]}
    else
      {ast, acc}
    end
  end

  defp traverse(ast, acc), do: {ast, acc}

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "Avoid using multiple pipes (`|>`) on the same line.",
      line_no: line_no,
      trigger: "|>"
    )
  end
end
