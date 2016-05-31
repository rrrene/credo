defmodule Credo.Check.Readability.TrailingWhiteSpace do
  @moduledoc """
  There should be no white-space (i.e. tabs, spaces) at the end of a line.
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :low

  def run(%SourceFile{lines: lines} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    traverse_line(lines, [], issue_meta)
  end

  defp traverse_line([{line_no, line} | tail], issues, issue_meta) do
    issues =
      case Regex.run(~r/\s+$/, line, return: :index) do
        [{column, line_length}] ->
          [issue_for(issue_meta, line_no, column + 1, line_length) | issues]
        nil -> issues
      end
    traverse_line(tail, issues, issue_meta)
  end
  defp traverse_line([], issues, _issue_meta), do: issues

  def issue_for(issue_meta, line_no, column, line_length) do
    format_issue issue_meta,
      message: "There should be no trailing white-space at the end of a line.",
      line_no: line_no,
      column: column,
      trigger: String.duplicate(" ", line_length)
  end
end
