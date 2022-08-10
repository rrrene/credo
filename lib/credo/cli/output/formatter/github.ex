defmodule Credo.CLI.Output.Formatter.Github do
  @moduledoc false

  alias Credo.CLI.Output.UI
  alias Credo.Issue
  alias Credo.Priority

  def print_issues(issues) do
    issues
    |> Enum.sort_by(fn issue -> {issue.filename, issue.line_no, issue.column} end)
    |> Enum.each(fn issue ->
      UI.puts(to_github(issue))
    end)
  end

  defp to_github(
         %Issue{
           check: check,
           filename: filename,
           line_no: line_no,
           message: message,
           priority: priority
         } = issue
       ) do
    check_name =
      check
      |> to_string()
      |> String.replace(~r/^(Elixir\.)/, "")

    column_end =
      if issue.column && issue.trigger do
        issue.column + String.length(to_string(issue.trigger))
      end

    type =
      case Priority.to_atom(priority) do
        :higher -> "error"
        :high -> "error"
        :normal -> "warning"
        _ -> "notice"
      end

    [
      "::#{type} ",
      "file=#{to_string(filename)},",
      "line=#{line_no},",
      "col=#{issue.column},",
      "endColumn=#{column_end},",
      "title=#{check_name}",
      "::#{message}"
    ]
  end
end
