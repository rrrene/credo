defmodule Credo.CLI.Output.Explain do
  alias Credo.Code.Scope
  alias Credo.CLI.Filter
  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI
  alias Credo.SourceFile
  alias Credo.Issue

  @indent 8
  @params_min_indent 20

  @doc "Called before the analysis is run."
  def print_before_info(source_files, exec) do
    UI.puts
    case Enum.count(source_files) do
      0 -> UI.puts "No files found!"
      1 -> UI.puts "Checking 1 source file ..."
      count -> UI.puts "Checking #{count} source files ..."
    end

    Output.print_skipped_checks(exec)
  end

  @doc "Called after the analysis has run."
  def print_after_info(source_file, exec, line_no, column) do
    term_width = Output.term_columns

    print_issues(source_file, exec, term_width, line_no, column)
  end

  defp print_issues(nil, _exec, _term_width, _line_no, _column) do
    nil
  end

  defp print_issues(%SourceFile{filename: filename} = source_file, exec, term_width, line_no, column) do
    issues = Credo.Execution.get_issues(exec, filename)

    issues
    |> Filter.important(exec)
    |> Filter.valid_issues(exec)
    |> Enum.sort_by(&(&1.line_no))
    |> filter_issues(line_no, column)
    |> print_issues(filename, source_file, exec, term_width, line_no, column)
  end

  defp print_issues([], _filename, _source_file, _exec, _term_width, _line_no, _column) do
    nil
  end

  defp print_issues(issues, _filename, source_file, _exec, term_width, _line_no, _column) do
    first_issue = issues |> List.first
    scope_name = Scope.mod_name(first_issue.scope)
    color = Output.check_color(first_issue)

    UI.puts

    [
      :bright, "#{color}_background" |> String.to_atom, color, " ",
        Output.foreground_color(color), :normal,
      " #{scope_name}" |> Credo.Backports.String.pad_trailing(term_width - 1),
    ]
    |> UI.puts

    UI.puts_edge(color)

    issues
    |> Enum.each(&print_issue(&1, source_file, term_width))
  end

  defp filter_issues(issues, line_no, nil) do
    line_no = line_no |> String.to_integer
    issues |> Enum.filter(&filter_issue(&1, line_no, nil))
  end
  defp filter_issues(issues, line_no, column) do
    line_no = line_no |> String.to_integer
    column = column |> String.to_integer

    issues |> Enum.filter(&filter_issue(&1, line_no, column))
  end

  defp filter_issue(%Issue{line_no: a, column: b}, a, b), do: true
  defp filter_issue(%Issue{line_no: a}, a, _), do: true
  defp filter_issue(_, _, _), do: false

  defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, source_file, term_width) do
    pos =
      pos_string(issue.line_no, issue.column)

    outer_color = Output.check_color(issue)
    inner_color = Output.check_color(issue)
    message_color  = inner_color
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

    UI.puts_edge(outer_color)

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
      UI.puts_edge([outer_color, :faint])

      [
        UI.edge([outer_color, :faint]), :reset, :color239,
          String.duplicate(" ", @indent - 5), "__ CODE IN QUESTION"
      ]
      |> UI.puts

      UI.puts_edge([outer_color, :faint])

      code_color = :faint
      print_source_line(source_file, issue.line_no - 2, term_width, code_color, outer_color)
      print_source_line(source_file, issue.line_no - 1, term_width, code_color, outer_color)
      print_source_line(source_file, issue.line_no, term_width, [:cyan, :bright], outer_color)

      if issue.column do
        offset = 0
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
      print_source_line(source_file, issue.line_no + 1, term_width, code_color, outer_color)
      print_source_line(source_file, issue.line_no + 2, term_width, code_color, outer_color)
    end

    UI.puts_edge([outer_color, :faint], @indent)

    [
      UI.edge([outer_color, :faint]), :reset, :color239,
        String.duplicate(" ", @indent - 5), "__ WHY IT MATTERS"
    ]
    |> UI.puts

    UI.puts_edge([outer_color, :faint])

    (issue.check.explanation || "TODO: Insert explanation")
    |> Credo.Backports.String.trim
    |> String.split("\n")
    |> Enum.flat_map(&format_explanation(&1, outer_color))
    |> Enum.slice(0..-2)
    |> UI.puts

    UI.puts_edge([outer_color, :faint])

    issue.check
    |> print_params_explanation(outer_color)

    UI.puts_edge([outer_color, :faint])
  end

  defp print_source_line(_, line_no, _, _, _) when line_no < 1 do
    nil
  end
  defp print_source_line(source_file, line_no, term_width, color, outer_color) do
    line = SourceFile.line_at(source_file, line_no)

    line_no_str =
      "#{line_no} "
      |> Credo.Backports.String.pad_leading(@indent - 2)

    [
      UI.edge([outer_color, :faint]), :reset,
        :faint, line_no_str, :reset,
        color, UI.truncate(line, term_width - @indent)
    ]
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

  def print_params_explanation(nil, _), do: nil
  def print_params_explanation(check, outer_color) do
    check_name = check |> to_string |> String.replace(~r/^Elixir\./, "")

    [
      UI.edge([outer_color, :faint]), :reset, :color239,
        String.duplicate(" ", @indent-5), "__ CONFIGURATION OPTIONS",
    ]
    |> UI.puts

    UI.puts_edge([outer_color, :faint])

    print_params_explanation(outer_color, check_name, check.explanation_for_params, check.params_defaults)
  end

  def print_params_explanation(outer_color, check_name, [], _defaults) do
    [
      UI.edge([outer_color, :faint]), :reset,
        String.duplicate(" ", @indent-2), "You can disable this check by using this tuple"
    ]
    |> UI.puts

    UI.puts_edge([outer_color, :faint])

    [
      UI.edge([outer_color, :faint]), :reset,
        String.duplicate(" ", @indent-2), "  {", :cyan, check_name, :reset, ", ", :cyan, "false", :reset ,"}"
    ]
    |> UI.puts

    UI.puts_edge([outer_color, :faint])

    [
      UI.edge([outer_color, :faint]), :reset,
        String.duplicate(" ", @indent-2), "There are no other configuration options."
    ]
    |> UI.puts

    UI.puts_edge([outer_color, :faint])
  end
  def print_params_explanation(outer_color, check_name, keywords, defaults) do
    [
      UI.edge([outer_color, :faint]), :reset,
        String.duplicate(" ", @indent-2), "To configure this check, use this tuple"
    ]
    |> UI.puts

    UI.puts_edge([outer_color, :faint])

    [
      UI.edge([outer_color, :faint]), :reset,
        String.duplicate(" ", @indent-2), "  {", :cyan, check_name, :reset, ", ", :cyan, :faint, "<params>", :reset ,"}"
    ]
    |> UI.puts

    UI.puts_edge([outer_color, :faint])

    [
      UI.edge([outer_color, :faint]), :reset,
        String.duplicate(" ", @indent-2), "with ", :cyan, :faint, "<params>", :reset ," being ", :cyan, "false", :reset, " or any combination of these keywords:"
    ]
    |> UI.puts

    UI.puts_edge([outer_color, :faint])

    params_indent = get_params_indent(keywords, @params_min_indent)

    keywords
    |> Enum.each(fn({param, text}) ->
        [
          UI.edge([outer_color, :faint]), :reset,
            String.duplicate(" ", @indent-2),
            :cyan, "  #{param}:" |> Credo.Backports.String.pad_trailing(params_indent+3),
            :reset, text
        ]
        |> UI.puts

        default = defaults[param]

        if default do
          default_text = "(defaults to #{inspect(default)})"
          [
            UI.edge([outer_color, :faint]), :reset,
              String.duplicate(" ", @indent-2),
              :cyan, " " |> Credo.Backports.String.pad_trailing(params_indent+3),
              :reset, :faint, default_text
          ]
          |> UI.puts
        end
      end)
  end

  defp get_params_indent(keywords, min_indent) do
    params_indent =
      Enum.reduce(keywords, min_indent, fn({param, _text}, current) ->
        size = param |> to_string |> String.length()

        if size > current do
          size
        else
          current
        end
      end)

    # Round up to the next multiple of 2
    (trunc(params_indent / 2) + 1) * 2
  end
end
