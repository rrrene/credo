defmodule Credo.CLI.Output.Formatter.Oneline do
  @moduledoc false

  alias Credo.CLI.Filename
  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI
  alias Credo.Issue

  def print_issues(issues) do
    issues
    |> Enum.sort_by(fn issue -> {issue.filename, issue.line_no, issue.column} end)
    |> Enum.each(fn issue ->
      UI.puts(to_oneline(issue))
    end)
  end

  defp to_oneline(
         %Issue{
           check: check,
           message: message,
           filename: filename,
           priority: priority
         } = issue
       ) do
    inner_color = Output.check_color(issue)
    message_color = inner_color
    filename_color = :default_color

    [
      inner_color,
      Output.check_tag(check.category),
      " ",
      priority |> Output.priority_arrow(),
      " ",
      :reset,
      filename_color,
      :faint,
      filename |> to_string,
      :default_color,
      :faint,
      Filename.pos_suffix(issue.line_no, issue.column),
      :reset,
      message_color,
      " ",
      message
    ]
  end
end
