defmodule Credo.Check.Readability.TrailingBlankLine do
  use Credo.Check,
    id: "EX3028",
    base_priority: :low,
    tags: [:formatter],
    explanations: [
      check: """
      Files should end in a trailing blank line.

      This is mostly for historical reasons: every text file should end with a \\n,
      or newline since this acts as `eol` or the end of the line character.

      See also: http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap03.html#tag_03_206

      Most text editors ensure this "final newline" automatically.

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    {line_no, last_line} =
      source_file
      |> SourceFile.lines()
      |> List.last()

    if String.trim(last_line) == "" do
      []
    else
      [issue_for(issue_meta, line_no)]
    end
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "There should be a final \\n at the end of each file.",
      line_no: line_no,
      trigger: Issue.no_trigger()
    )
  end
end
