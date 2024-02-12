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

    Credo.Code.to_tokens(source_file)
    |> Enum.filter(&filter_pipes/1)
    |> Enum.group_by(fn {_, {line, _, _}, :|>} -> line end)
    |> Enum.filter(&filter_tokens/1)
    |> Enum.map(fn {_, [{_, {line_no, column, _}, _} | _]} ->
      issue_for(issue_meta, line_no, column)
    end)
  end

  defp filter_pipes({:arrow_op, _, :|>}), do: true
  defp filter_pipes(_), do: false

  defp filter_tokens({_, [_]}), do: false
  defp filter_tokens({_, [_ | _]}), do: true
  defp filter_tokens(_), do: false

  defp issue_for(issue_meta, line_no, column) do
    format_issue(
      issue_meta,
      message: "Avoid using multiple pipes (`|>`) on the same line.",
      line_no: line_no,
      column: column,
      trigger: "|>"
    )
  end
end
