defmodule Credo.CLI.Output.IssueHelper do
  alias Credo.CLI.Filename
  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI
  alias Credo.Config
  alias Credo.Issue

  @indent 8

  def print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, _source_file,
                    %Config{one_line: true} = _config, _term_width) do
    inner_color = Output.check_color(issue)
    message_color  = inner_color
    filename_color = :white

    [
      inner_color,
      Output.check_tag(check.category), " ", priority |> Output.priority_arrow, " ",
      :reset, filename_color, :faint, filename |> to_string,
      :default_color, :faint, Filename.pos_suffix(issue.line_no, issue.column),
      :reset, message_color,  " ", message,
    ]
    |> UI.puts
  end
  def print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file,
                    %Config{one_line: false} = config, term_width) do
    outer_color = Output.check_color(issue)
    inner_color = Output.issue_color(issue)
    message_color  = outer_color
    filename_color = :white
    tag_style = if outer_color == inner_color, do: :faint, else: :bright

    [
      UI.edge(outer_color),
        outer_color,
        tag_style,
        Output.check_tag(check.category), " ", priority |> Output.priority_arrow,
        :normal, message_color, " ", message,
    ]
    |> UI.puts

    [
      UI.edge(outer_color, @indent),
        filename_color, :faint, filename |> to_string,
        :default_color, :faint, Filename.pos_suffix(issue.line_no, issue.column),
        :faint, " (#{issue.scope})"
    ]
    |> UI.puts

    if config.verbose do
      print_issue_line(issue, source_file, inner_color, outer_color, term_width)

      UI.edge([outer_color, :faint])
      |> UI.puts
    end
  end

  defp print_issue_line(%Issue{line_no: nil}, _source_file, _inner_color, _outer_color, _term_width) do
    nil
  end
  defp print_issue_line(%Issue{} = issue, source_file, inner_color, outer_color, term_width) do
    {_, line} = Enum.at(source_file.lines, issue.line_no-1)

    displayed_line = String.strip(line)
    if String.length(displayed_line) > term_width do
      ellipsis = " ..."
      displayed_line = String.slice(displayed_line, 0, term_width-@indent-String.length(ellipsis)) <> ellipsis
    end

    [outer_color, :faint]
    |> UI.edge
    |> UI.puts

    [
      UI.edge([outer_color, :faint]), :cyan, :faint,
        String.duplicate(" ", @indent-2), displayed_line
    ]
    |> UI.puts

    print_issue_trigger_marker(issue, line, inner_color, outer_color)
  end

  defp print_issue_trigger_marker(%Issue{column: nil}, _line, _inner_color, _outer_color) do
    nil
  end
  defp print_issue_trigger_marker(%Issue{} = issue, line, inner_color, outer_color) do
    offset = String.length(line) - String.length(String.strip(line))
    x = max(issue.column - offset - 1, 0) # column is one-based
    w =
      case issue.trigger do
        nil -> 1
        atom -> atom |> to_string |> String.length
      end

    [
      UI.edge([outer_color, :faint], @indent),
        inner_color, String.duplicate(" ", x),
        :faint, String.duplicate("^", w)
    ]
    |> UI.puts
  end
end
