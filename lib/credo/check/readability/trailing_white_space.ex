defmodule Credo.Check.Readability.TrailingWhiteSpace do
  @moduledoc """
  There should be no white-space (i.e. tabs, spaces) at the end of a line.

  Most text editors provide a way to remove them automatically.
  """

  @explanation [
    check: @moduledoc,
    params: [
      ignore_strings: "Set to `false` to check lines that are strings or in heredocs",
    ]
  ]
  @default_params [
    ignore_strings: true
  ]

  use Credo.Check, base_priority: :low
  alias Credo.Code
  alias Credo.Code.Strings

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    ignore_strings = Params.get(params, :ignore_strings, @default_params)

    source_file
    |> to_lines(ignore_strings)
    |> traverse_line([], issue_meta)
  end

  defp to_lines(source_file, true) do
    source_file
    |> SourceFile.source
    |> Strings.replace_with_spaces(".")
    |> Code.to_lines
  end
  defp to_lines(source_file, false) do
    SourceFile.lines(source_file)
  end

  defp traverse_line([{line_no, line} | tail], issues, issue_meta) do
    issues =
      case Regex.run(~r/\s+$/, line, return: :index) do
        [{column, line_length}] ->
          [issue_for(issue_meta, line_no, column + 1, line_length) | issues]
        nil ->
          issues
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
