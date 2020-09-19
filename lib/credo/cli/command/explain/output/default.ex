defmodule Credo.CLI.Command.Explain.Output.Default do
  @moduledoc false

  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI
  alias Credo.Code.Scope

  @indent 8
  @params_min_indent 10

  @doc "Called before the analysis is run."
  def print_before_info(source_files, exec) do
    UI.puts()

    case Enum.count(source_files) do
      0 -> UI.puts("No files found!")
      1 -> UI.puts("Checking 1 source file ...")
      count -> UI.puts("Checking #{count} source files ...")
    end

    Output.print_skipped_checks(exec)
  end

  @doc "Called after the analysis has run."
  def print_after_info(explanations, exec, nil, nil) do
    term_width = Output.term_columns()

    print_explanations_for_check(explanations, exec, term_width)
  end

  def print_after_info(explanations, exec, line_no, column) do
    term_width = Output.term_columns()

    print_explanations_for_issue(explanations, exec, term_width, line_no, column)
  end

  #
  # CHECK
  #

  defp print_explanations_for_check(explanations, _exec, term_width) do
    Enum.each(explanations, &print_check(&1, term_width))
  end

  defp print_check(
         %{
           category: category,
           check: check,
           explanation_for_issue: explanation_for_issue,
           priority: priority
         },
         term_width
       ) do
    check_name = check |> to_string |> String.replace(~r/^Elixir\./, "")
    color = Output.check_color(check.category)

    UI.puts()

    [
      :bright,
      "#{color}_background" |> String.to_atom(),
      color,
      " ",
      Output.foreground_color(color),
      :normal,
      " Check: #{check_name}" |> String.pad_trailing(term_width - 1)
    ]
    |> UI.puts()

    UI.puts_edge(color)

    outer_color = Output.check_color(category)
    inner_color = Output.check_color(category)

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
      :reset,
      " Category: #{check.category} "
    ]
    |> UI.puts()

    [
      UI.edge(outer_color),
      inner_color,
      tag_style,
      "   ",
      priority |> Output.priority_arrow(),
      :reset,
      "  Priority: #{Output.priority_name(priority)} "
    ]
    |> UI.puts()

    UI.puts_edge(outer_color)

    UI.puts_edge([outer_color, :faint], @indent)

    print_check_explanation(explanation_for_issue, outer_color)
    print_params_explanation(check, outer_color)

    UI.puts_edge([outer_color, :faint])
  end

  #
  # ISSUE
  #

  defp print_explanations_for_issue(
         [],
         _exec,
         _term_width,
         _line_no,
         _column
       ) do
    nil
  end

  defp print_explanations_for_issue(
         explanations,
         _exec,
         term_width,
         _line_no,
         _column
       ) do
    first_explanation = explanations |> List.first()
    scope_name = Scope.mod_name(first_explanation.scope)
    color = Output.check_color(first_explanation.category)

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

    UI.puts_edge(color)

    Enum.each(explanations, &print_issue(&1, term_width))
  end

  defp print_issue(
         %{
           category: category,
           check: check,
           column: column,
           explanation_for_issue: explanation_for_issue,
           filename: filename,
           trigger: trigger,
           line_no: line_no,
           message: message,
           priority: priority,
           related_code: related_code,
           scope: scope
         },
         term_width
       ) do
    pos = pos_string(line_no, column)

    outer_color = Output.check_color(category)
    inner_color = Output.check_color(category)
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
      "  ",
      Output.check_tag(check.category),
      :reset,
      " Category: #{check.category} "
    ]
    |> UI.puts()

    [
      UI.edge(outer_color),
      inner_color,
      tag_style,
      "   ",
      priority |> Output.priority_arrow(),
      :reset,
      "  Priority: #{Output.priority_name(priority)} "
    ]
    |> UI.puts()

    UI.puts_edge(outer_color)

    [
      UI.edge(outer_color),
      inner_color,
      tag_style,
      "    ",
      :normal,
      message_color,
      "  ",
      message
    ]
    |> UI.puts()

    [
      UI.edge(outer_color, @indent),
      filename_color,
      :faint,
      to_string(filename),
      :default_color,
      :faint,
      pos,
      :faint,
      " (#{scope})"
    ]
    |> UI.puts()

    if line_no do
      print_issue_line_no(
        term_width,
        line_no,
        column,
        trigger,
        related_code,
        outer_color,
        inner_color
      )
    end

    UI.puts_edge([outer_color, :faint], @indent)

    print_check_explanation(explanation_for_issue, outer_color)
    print_params_explanation(check, outer_color)

    UI.puts_edge([outer_color, :faint])
  end

  def print_check_explanation(explanation_for_issue, outer_color) do
    [
      UI.edge([outer_color, :faint]),
      :reset,
      :color239,
      String.duplicate(" ", @indent - 5),
      "__ WHY IT MATTERS"
    ]
    |> UI.puts()

    UI.puts_edge([outer_color, :faint])

    (explanation_for_issue || "TODO: Insert explanation")
    |> String.trim()
    |> String.split("\n")
    |> Enum.flat_map(&format_explanation(&1, outer_color))
    |> Enum.slice(0..-2)
    |> UI.puts()

    UI.puts_edge([outer_color, :faint])
  end

  def format_explanation(line, outer_color) do
    [
      UI.edge([outer_color, :faint], @indent),
      :reset,
      line |> format_explanation_text,
      "\n"
    ]
  end

  def format_explanation_text("    " <> line) do
    [:yellow, :faint, "    ", line]
  end

  def format_explanation_text(line) do
    # TODO: format things in backticks in help texts
    # case Regex.run(~r/(\`[a-zA-Z_\.]+\`)/, line) do
    #  v ->
    #    # IO.inspect(v)
    [:reset, line]
    # end
  end

  defp pos_string(nil, nil), do: ""
  defp pos_string(line_no, nil), do: ":#{line_no}"
  defp pos_string(line_no, column), do: ":#{line_no}:#{column}"

  def print_params_explanation(nil, _), do: nil

  def print_params_explanation(check, outer_color) do
    check_name = check |> to_string |> String.replace(~r/^Elixir\./, "")

    [
      UI.edge([outer_color, :faint]),
      :reset,
      :color239,
      String.duplicate(" ", @indent - 5),
      "__ CONFIGURATION OPTIONS"
    ]
    |> UI.puts()

    UI.puts_edge([outer_color, :faint])

    print_params_explanation(
      outer_color,
      check_name,
      check.explanations()[:params],
      check.param_defaults()
    )
  end

  def print_params_explanation(outer_color, check_name, param_explanations, _defaults)
      when param_explanations in [nil, []] do
    [
      UI.edge([outer_color, :faint]),
      :reset,
      String.duplicate(" ", @indent - 2),
      "You can disable this check by using this tuple"
    ]
    |> UI.puts()

    UI.puts_edge([outer_color, :faint])

    [
      UI.edge([outer_color, :faint]),
      :reset,
      String.duplicate(" ", @indent - 2),
      "  {",
      :cyan,
      check_name,
      :reset,
      ", ",
      :cyan,
      "false",
      :reset,
      "}"
    ]
    |> UI.puts()

    UI.puts_edge([outer_color, :faint])

    [
      UI.edge([outer_color, :faint]),
      :reset,
      String.duplicate(" ", @indent - 2),
      "There are no other configuration options."
    ]
    |> UI.puts()

    UI.puts_edge([outer_color, :faint])
  end

  def print_params_explanation(outer_color, check_name, keywords, defaults) do
    [
      UI.edge([outer_color, :faint]),
      :reset,
      String.duplicate(" ", @indent - 2),
      "To configure this check, use this tuple"
    ]
    |> UI.puts()

    UI.puts_edge([outer_color, :faint])

    [
      UI.edge([outer_color, :faint]),
      :reset,
      String.duplicate(" ", @indent - 2),
      "  {",
      :cyan,
      check_name,
      :reset,
      ", ",
      :cyan,
      :faint,
      "<params>",
      :reset,
      "}"
    ]
    |> UI.puts()

    UI.puts_edge([outer_color, :faint])

    [
      UI.edge([outer_color, :faint]),
      :reset,
      String.duplicate(" ", @indent - 2),
      "with ",
      :cyan,
      :faint,
      "<params>",
      :reset,
      " being ",
      :cyan,
      "false",
      :reset,
      " or any combination of these keywords:"
    ]
    |> UI.puts()

    UI.puts_edge([outer_color, :faint])

    params_indent = get_params_indent(keywords, @params_min_indent)

    keywords
    |> Enum.each(fn {param, text} ->
      [head | tail] = String.split(text, "\n")

      [
        UI.edge([outer_color, :faint]),
        :reset,
        String.duplicate(" ", @indent - 2),
        :cyan,
        "  #{param}:" |> String.pad_trailing(params_indent + 3),
        :reset,
        head
      ]
      |> UI.puts()

      tail
      |> List.wrap()
      |> Enum.each(fn line ->
        [
          UI.edge([outer_color, :faint]),
          :reset,
          String.duplicate(" ", @indent - 2),
          :cyan,
          String.pad_trailing("", params_indent + 3),
          :reset,
          line
        ]
        |> UI.puts()
      end)

      default = defaults[param]

      if default do
        default_text = "(defaults to #{inspect(default)})"

        [
          UI.edge([outer_color, :faint]),
          :reset,
          String.duplicate(" ", @indent - 2),
          :cyan,
          " " |> String.pad_trailing(params_indent + 3),
          :reset,
          :faint,
          default_text
        ]
        |> UI.puts()
      end
    end)
  end

  defp get_params_indent(keywords, min_indent) do
    params_indent =
      Enum.reduce(keywords, min_indent, fn {param, _text}, current ->
        size =
          param
          |> to_string
          |> String.length()

        if size > current do
          size
        else
          current
        end
      end)

    # Round up to the next multiple of 2
    (trunc(params_indent / 2) + 1) * 2
  end

  defp print_issue_column(column, trigger, outer_color, inner_color) do
    offset = 0
    # column is one-based
    x = max(column - offset - 1, 0)

    w =
      if is_nil(trigger) do
        1
      else
        trigger
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

  defp print_issue_line_no(
         term_width,
         line_no,
         column,
         trigger,
         related_code,
         outer_color,
         inner_color
       ) do
    UI.puts_edge([outer_color, :faint])

    [
      UI.edge([outer_color, :faint]),
      :reset,
      :color239,
      String.duplicate(" ", @indent - 5),
      "__ CODE IN QUESTION"
    ]
    |> UI.puts()

    UI.puts_edge([outer_color, :faint])

    code_color = :faint

    print_source_line(
      related_code,
      line_no - 2,
      term_width,
      code_color,
      outer_color
    )

    print_source_line(
      related_code,
      line_no - 1,
      term_width,
      code_color,
      outer_color
    )

    print_source_line(
      related_code,
      line_no,
      term_width,
      [:cyan, :bright],
      outer_color
    )

    if column, do: print_issue_column(column, trigger, outer_color, inner_color)

    print_source_line(
      related_code,
      line_no + 1,
      term_width,
      code_color,
      outer_color
    )

    print_source_line(
      related_code,
      line_no + 2,
      term_width,
      code_color,
      outer_color
    )
  end

  defp print_source_line(related_code, line_no, term_width, code_color, outer_color) do
    line =
      related_code
      |> Enum.find_value(fn
        {line_no2, line} when line_no2 == line_no -> line
        _ -> nil
      end)

    if line do
      line_no_str =
        "#{line_no} "
        |> String.pad_leading(@indent - 2)

      [
        UI.edge([outer_color, :faint]),
        :reset,
        :faint,
        line_no_str,
        :reset,
        code_color,
        UI.truncate(line, term_width - @indent)
      ]
      |> UI.puts()
    end
  end
end
