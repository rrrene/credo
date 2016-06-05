defmodule Credo.CLI.Output.IssueHelper do
  alias Credo.CLI.Filename
  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI
  alias Credo.Config
  alias Credo.Issue

  @indent 8

  def print_issue(%Issue{check: _check, message: message, filename: filename, priority: _priority} = issue, _source_file,
                    %Config{format: "flycheck"} = _config, _term_width) do
    tag = Output.check_tag(issue, false)

    [
      filename |> to_string, Filename.pos_suffix(issue.line_no, issue.column), ": ", tag, ": ", message,
    ]
    |> UI.puts
  end
  def print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, _source_file,
                    %Config{format: "oneline"} = _config, _term_width) do
    inner_color = Output.check_color(issue)
    message_color  = inner_color
    filename_color = :default_color

    [
      inner_color,
      Output.check_tag(check.category), " ", priority |> Output.priority_arrow, " ",
      :reset, filename_color, :faint, filename |> to_string,
      :default_color, :faint, Filename.pos_suffix(issue.line_no, issue.column),
      :reset, message_color,  " ", message,
    ]
    |> UI.puts
  end
  def print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file, %Config{format: _} = config, term_width) do
    outer_color = Output.check_color(issue)
    inner_color = Output.issue_color(issue)
    message_color  = outer_color
    filename_color = :default_color
    tag_style = if outer_color == inner_color, do: :faint, else: :bright

    message
    |> UI.wrap_at(term_width - @indent)
    |> print_issue_message(check, outer_color, message_color, tag_style, priority)

    [
      UI.edge(outer_color, @indent),
        filename_color, :faint, filename |> to_string,
        :default_color, :faint, Filename.pos_suffix(issue.line_no, issue.column),
        :faint, " (#{issue.scope})"
    ]
    |> UI.puts

    if config.verbose do
      print_issue_line(issue, source_file, inner_color, outer_color, term_width)

      UI.puts_edge([outer_color, :faint])
    end
  end

  defp print_issue_message([first_line | other_lines], check, outer_color, message_color, tag_style, priority) do
    [
      UI.edge(outer_color),
        outer_color,
        tag_style,
        Output.check_tag(check.category), " ", priority |> Output.priority_arrow,
        :normal, message_color, " ", first_line,
    ]
    |> UI.puts

    other_lines
    |> Enum.each(&print_issue_message(&1, outer_color, message_color))
  end
  defp print_issue_message("", _outer_color, _message_color) do
  end
  defp print_issue_message(message, outer_color, message_color) do
    [
      UI.edge(outer_color),
        outer_color,
        String.duplicate(" ", @indent - 3),
        :normal, message_color, " ", message,
    ]
    |> UI.puts
  end

  defp print_issue_line(%Issue{line_no: nil}, _source_file, _inner_color, _outer_color, _term_width) do
    nil
  end
  defp print_issue_line(%Issue{} = issue, source_file, inner_color, outer_color, term_width) do
    {_, raw_line} = Enum.at(source_file.lines, issue.line_no - 1)
    line = raw_line |> String.strip

    [outer_color, :faint]
    |> UI.edge
    |> UI.puts

    [
      UI.edge([outer_color, :faint]), :cyan, :faint,
        String.duplicate(" ", @indent-2),
        UI.truncate(line, term_width - @indent)
    ]
    |> UI.puts

    print_issue_trigger_marker(issue, raw_line, inner_color, outer_color)
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
