defmodule Credo.CLI.Output.Explain do
  alias Credo.Code.Scope
  alias Credo.CLI.Filter
  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI
  alias Credo.SourceFile
  alias Credo.Issue

  @indent 8

  @doc "Called before the analysis is run."
  def print_before_info(source_files) do
    UI.puts
    case Enum.count(source_files) do
      0 -> UI.puts "No files found!"
      1 -> UI.puts "Checking 1 source file ..."
      count -> UI.puts "Checking #{count} source files ..."
    end
  end

  @doc "Called after the analysis has run."
  def print_after_info(source_file, config, line_no, column) do
    term_width = Output.term_columns

    print_issues(source_file, config, term_width, line_no, column)
  end

  defp print_issues(nil, _config, _term_width, _line_no, _column) do
    nil
  end
  defp print_issues(%SourceFile{issues: issues, filename: filename} = source_file, config, term_width, line_no, column) do
    issues
    |> Filter.important(config)
    |> Enum.sort_by(&(&1.line_no))
    |> print_issues(filename, source_file, config, term_width, line_no, column)
  end

  defp print_issues([], _filename, _source_file, _config, _term_width, _line_no, _column) do
    nil
  end
  defp print_issues(issues, _filename, source_file, _config, term_width, line_no, column) do
    if line_no, do: issues = issues |> Enum.filter(&(&1.line_no == line_no |> String.to_integer))
    if column, do: issues = issues |> Enum.filter(&(&1.column == column |> String.to_integer))

    first_issue = issues |> List.first
    scope_name = Scope.mod_name(first_issue.scope)
    color = Output.check_color(first_issue)

    UI.puts

    [
      :bright, "#{color}_background" |> String.to_atom, color, " ",
        Output.foreground_color(color), :normal,
      " #{scope_name}" |> String.ljust(term_width-1),
    ]
    |> UI.puts

    UI.edge(color)
    |> UI.puts

    issues
    |> Enum.each(&print_issue(&1, source_file, term_width))
  end

  defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file, term_width) do
    pos =
      pos_string(issue.line_no, issue.column)

    outer_color = Output.check_color(issue)
    inner_color = Output.check_color(issue)
    message_color  = inner_color
    filename_color = :white
    tag_style = if outer_color == inner_color, do: :faint, else: :bright

    [
      UI.edge(outer_color),
        inner_color,
        tag_style,
         "  ",
        Output.check_tag(check.category),
        :reset, " Category: #{check.category} "
    ]
    |> UI.puts

    [
      UI.edge(outer_color),
        inner_color,
        tag_style,
        "   ",
        priority |> Output.priority_arrow,
        :reset, "  Priority: #{Output.priority_name(priority)} "
    ]
    |> UI.puts

    outer_color
    |> UI.edge
    |> UI.puts

    [
      UI.edge(outer_color),
        inner_color,
        tag_style,
        "    ",
        :normal, message_color, "  ", message,
    ]
    |> UI.puts

    [
      UI.edge(outer_color, @indent),
        filename_color, :faint, filename |> to_string,
        :default_color, :faint, pos,
        :faint, " (#{issue.scope})"
    ]
    |> UI.puts

    if issue.line_no do
      {_, line} = Enum.at(source_file.lines, issue.line_no-1)

      displayed_line = String.strip(line)
      if String.length(displayed_line) > term_width do
        ellipsis = " ..."
        displayed_line = String.slice(displayed_line, 0, term_width-@indent-String.length(ellipsis)) <> ellipsis
      end

      UI.edge([outer_color, :faint])
      |> UI.puts

      [
        UI.edge([outer_color, :faint]), :reset, :color239,
          String.duplicate(" ", @indent-5), "__ CODE IN QUESTION"
      ]
      |> UI.puts

      UI.edge([outer_color, :faint])
      |> UI.puts

      [
        UI.edge([outer_color, :faint]), :reset, :cyan, :bright,
          String.duplicate(" ", @indent-2), displayed_line
      ]
      |> UI.puts
    end
    if issue.column do
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

    UI.edge([outer_color, :faint], @indent)
    |> UI.puts

    [
      UI.edge([outer_color, :faint]), :reset, :color239,
        String.duplicate(" ", @indent-5), "__ WHY IT MATTERS"
    ]
    |> UI.puts

    UI.edge([outer_color, :faint])
    |> UI.puts

    (issue.check.explanation || "TODO: Insert explanation")
    |> String.strip
    |> String.split("\n")
    |> Enum.map(&format_explanation(&1, outer_color))
    |> UI.puts
  end

  def format_explanation(line, outer_color) do
    [
      UI.edge([outer_color, :faint], @indent),
      :reset, line |> format_explanation_text,
      "\n"
    ]
  end
  def format_explanation_text("    " <> line) do
    [:yellow, :faint, "    ", line]
  end
  def format_explanation_text(line) do
    # TODO: format things in backticks in help texts
    #case Regex.run(~r/(\`[a-zA-Z_\.]+\`)/, line) do
    #  v ->
    #    # IO.inspect(v)
        [:reset, line]
    #end
  end

  defp pos_string(nil, nil), do: ""
  defp pos_string(line_no, nil), do: ":#{line_no}"
  defp pos_string(line_no, column), do: ":#{line_no}:#{column}"

end
