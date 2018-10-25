defmodule Credo.CLI.Command.List.Output.Default do
  @moduledoc false

  alias Credo.CLI.Filename
  alias Credo.CLI.Output
  alias Credo.CLI.Output.Summary
  alias Credo.CLI.Output.UI
  alias Credo.Code.Scope
  alias Credo.Issue
  alias Credo.SourceFile

  @indent 8

  @doc "Called before the analysis is run."
  def print_before_info(source_files, exec) do
    UI.puts("")

    case Enum.count(source_files) do
      0 -> UI.puts("No files found!")
      1 -> UI.puts("Checking 1 source file ...")
      count -> UI.puts("Checking #{count} source files ...")
    end

    Output.print_skipped_checks(exec)
  end

  @doc "Called after the analysis has run."
  def print_after_info(source_files, exec, time_load, time_run) do
    term_width = Output.term_columns()

    source_files
    |> Enum.sort_by(& &1.filename)
    |> Enum.each(&print_issues(&1, exec, term_width))

    source_files
    |> Summary.print(exec, time_load, time_run)
  end

  defp print_issues(
         %SourceFile{filename: filename} = source_file,
         exec,
         term_width
       ) do
    issues = Credo.Execution.get_issues(exec, filename)

    issues
    |> print_issues(filename, source_file, exec, term_width)
  end

  defp print_issues(issues, _filename, source_file, _exec, term_width) do
    if issues |> Enum.any?() do
      first_issue = issues |> List.first()
      scope_name = Scope.mod_name(first_issue.scope)
      color = Output.check_color(first_issue)

      UI.puts()

      [
        :bright,
        "#{color}_background" |> String.to_atom(),
        color,
        " ",
        Output.foreground_color(color),
        :normal,
        " #{scope_name}" |> String.pad_trailing(term_width - 1)
      ]
      |> UI.puts()

      color
      |> UI.edge()
      |> UI.puts()

      issues
      |> Enum.sort_by(& &1.line_no)
      |> Enum.each(&print_issue(&1, source_file, term_width))
    end
  end

  defp print_issue(
         %Issue{
           check: check,
           message: message,
           filename: filename,
           priority: priority
         } = issue,
         source_file,
         term_width
       ) do
    outer_color = Output.check_color(issue)
    inner_color = Output.issue_color(issue)
    message_color = inner_color
    filename_color = :default_color

    tag_style =
      if outer_color == inner_color do
        :faint
      else
        :bright
      end

    [
      UI.edge(outer_color),
      inner_color,
      tag_style,
      Output.check_tag(check.category),
      " ",
      priority |> Output.priority_arrow(),
      :normal,
      message_color,
      " ",
      message
    ]
    |> UI.puts()

    [
      UI.edge(outer_color, @indent),
      filename_color,
      :faint,
      filename |> to_string,
      :default_color,
      :faint,
      Filename.pos_suffix(issue.line_no, issue.column),
      :faint,
      " (#{issue.scope})"
    ]
    |> UI.puts()

    if issue.line_no do
      print_issue_line_no(source_file, term_width, issue, outer_color, inner_color)
    end

    UI.puts_edge([outer_color, :faint], @indent)
  end

  defp print_issue_column(raw_line, line, issue, outer_color, inner_color) do
    offset = String.length(raw_line) - String.length(line)
    # column is one-based
    x = max(issue.column - offset - 1, 0)

    w =
      if is_nil(issue.trigger) do
        1
      else
        issue.trigger
        |> to_string()
        |> String.length()
      end

    [
      UI.edge([outer_color, :faint], @indent),
      inner_color,
      String.duplicate(" ", x),
      :faint,
      String.duplicate("^", w)
    ]
    |> UI.puts()
  end

  defp print_issue_line_no(source_file, term_width, issue, outer_color, inner_color) do
    raw_line = SourceFile.line_at(source_file, issue.line_no)
    line = String.trim(raw_line)

    UI.puts_edge([outer_color, :faint])

    [
      UI.edge([outer_color, :faint]),
      :cyan,
      :faint,
      String.duplicate(" ", @indent - 2),
      UI.truncate(line, term_width - @indent)
    ]
    |> UI.puts()

    if issue.column, do: print_issue_column(raw_line, line, issue, outer_color, inner_color)
  end
end
