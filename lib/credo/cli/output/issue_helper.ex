defmodule Credo.CLI.Output.IssueHelper do
  alias Credo.CLI.Filename
  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI
  alias Credo.Execution
  alias Credo.Issue
  alias Credo.SourceFile

  @indent 8

  def print_issues(issues, source_file_map, %Execution{format: _} = exec, term_width) do
    Enum.each(issues, fn(%Issue{filename: filename} = issue) ->
      source_file = source_file_map[filename]
      do_print_issue(issue, source_file, exec, term_width)
    end)
  end

  def do_print_issue(%Issue{check: _check, message: message, filename: filename, priority: _priority} = issue, _source_file,
                    %Execution{format: "flycheck"} = _exec, _term_width) do
    tag = Output.check_tag(issue, false)

    [
      filename |> to_string, Filename.pos_suffix(issue.line_no, issue.column), ": ", tag, ": ", message,
    ]
    |> UI.puts
  end
  def do_print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, _source_file,
                    %Execution{format: "oneline"} = _exec, _term_width) do
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
  def do_print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file,
                    %Execution{format: _} = exec, term_width) do
    outer_color = Output.check_color(issue)
    inner_color = Output.issue_color(issue)
    message_color  = outer_color
    filename_color = :default_color
    tag_style =
      if outer_color == inner_color do
        :faint
      else
        :bright
      end

    message
    |> UI.wrap_at(term_width - @indent)
    |> print_issue_message(check, outer_color, message_color, tag_style, priority)

    [
      UI.edge(outer_color, @indent),
        filename_color, :faint, filename |> to_string,
        :default_color, :faint, Filename.pos_suffix(issue.line_no, issue.column),
        :conceal, " #", :reset, :faint, "(#{issue.scope})"
    ]
    |> UI.puts

    if exec.verbose do
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
    raw_line = SourceFile.line_at(source_file, issue.line_no)
    line = Credo.Backports.String.trim(raw_line)

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
    offset = String.length(line) - String.length(Credo.Backports.String.trim(line))
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
