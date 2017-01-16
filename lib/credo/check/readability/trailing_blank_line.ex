defmodule Credo.Check.Readability.TrailingBlankLine do
  @moduledoc """
  For readability and Historical reason every text file should end with a \n,
  or newline. This act as eol, or the end of the line character.
  POSIX http://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap03.html#tag_03_206

  Files should end in a trailing blank line. Many editors ensure this
  "final newline" automatically.

  - For Vim users, you’re all set out of the box! Just don’t change your eol setting.
  - For Emacs users, add (setq require-final-newline t) to your .emacs or .emacs.d/init.el file.
  - For TextMate users, you can install the Avian Missing Bundle and
  add TM_STRIP_WHITESPACE_ON_SAVE = true to your .tm_properties file.
  - For Sublime users, set the ensure_newline_at_eof_on_save option to true.
  - For RubyMine, set “Ensure line feed at file end on Save” under “Editor.”
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :low

  @doc false
  def run(%SourceFile{lines: lines} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    {line_no, last_line} = List.last(lines)

    if String.strip(last_line) == "" do
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
