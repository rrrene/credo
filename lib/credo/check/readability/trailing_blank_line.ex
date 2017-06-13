defmodule Credo.Check.Readability.TrailingBlankLine do
  @moduledoc """
  Files should end in a trailing blank line.

  This is mostly for historical reasons: every text file should end with a \\n,
  or newline since this acts as `eol´ or the end of the line character.

  See also: http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap03.html#tag_03_206

  Most text editors ensure this "final newline" automatically.
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :low

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    {line_no, last_line} =
      source_file
      |> SourceFile.lines
      |> List.last

    if Credo.Backports.String.trim(last_line) == "" do
      []
    else
      [issue_for(issue_meta, line_no)]
    end
  end

  def issue_for(issue_meta, line_no) do
    format_issue issue_meta,
      message: "There should be a final \\n at the end of each file.",
      line_no: line_no
  end
end
