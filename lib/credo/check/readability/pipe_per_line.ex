defmodule Credo.Check.Readability.PipePerLine do
  use Credo.Check,
    base_priority: :high,
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

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @impl Credo.Check
  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.to_tokens(source_file)
    |> Enum.filter(&filter_pipes/1)
    |> Enum.group_by(fn {_, {line, _, _}, :|>} -> line end)
    |> Enum.filter(fn {_, tokens} -> length(tokens) > 1 end)
    |> Enum.map(fn {_, [{_, {line_no, column_no, _}, _} | _]} ->
      format_issue(
        issue_meta,
        message: "Don't use multiple |> in the same line",
        line_no: line_no,
        column: column_no,
        trigger: "|>"
      )
    end)
  end

  defp filter_pipes({:arrow_op, _, :|>}), do: true
  defp filter_pipes(_), do: false
end
