defmodule Credo.CLI.Output.Formatter.Flycheck do
  @moduledoc false

  alias Credo.CLI.Filename
  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI
  alias Credo.Issue

  def print_issues(issues) do
    Enum.each(issues, fn issue ->
      issue
      |> to_flycheck()
      |> UI.puts()
    end)
  end

  def to_flycheck(
        %Issue{
          message: message,
          filename: filename,
          column: column,
          line_no: line_no
        } = issue
      ) do
    pos_suffix = Filename.pos_suffix(line_no, column)
    tag = Output.check_tag(issue, false)

    "#{filename}#{pos_suffix}: #{tag}: #{message}"
  end
end
