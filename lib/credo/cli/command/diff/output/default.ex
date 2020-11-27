defmodule Credo.CLI.Command.Diff.Output.Default do
  @moduledoc false

  alias Credo.CLI.Command.Diff.DiffCommand
  alias Credo.CLI.Command.Diff.DiffSummary
  alias Credo.CLI.Filename
  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI
  alias Credo.CLI.Sorter
  alias Credo.Execution
  alias Credo.Issue
  alias Credo.SourceFile

  @category_starting_order [:design, :readability, :refactor]
  @category_ending_order [:warning, :consistency, :custom, :unknown]
  @category_colors [
    design: :olive,
    readability: :blue,
    refactor: :yellow,
    warning: :red,
    consistency: :cyan
  ]
  @category_titles [
    design: "Software Design",
    readability: "Code Readability",
    refactor: "Refactoring opportunities",
    warning: "Warnings - please take a look",
    consistency: "Consistency"
  ]
  @many_source_files 60
  @per_category 5
  @indent 8

  @doc "Called before the analysis is run."
  def print_before_info(source_files, exec) do
    {_, git_ref_or_range} = DiffCommand.previous_ref(exec)

    case Enum.count(source_files) do
      0 ->
        UI.puts("No files found!")

      1 ->
        UI.puts([
          :faint,
          "Diffing 1 source file in working dir with ",
          :cyan,
          git_ref_or_range,
          :reset,
          :faint,
          " ..."
        ])

      count ->
        UI.puts([
          :faint,
          "Diffing #{count} source files in working dir with ",
          :cyan,
          git_ref_or_range,
          :reset,
          :faint,
          "#{checking_suffix(count)} ..."
        ])
    end

    Output.print_skipped_checks(exec)
  end

  defp checking_suffix(count) when count > @many_source_files do
    " (this might take a while)"
  end

  defp checking_suffix(_), do: ""

  @doc "Called after the analysis has run."
  def print_after_info(source_files, exec, time_load, time_run) do
    term_width = Output.term_columns()

    issues = Execution.get_issues(exec)

    issues_to_display = Enum.filter(issues, &(&1.diff_marker == :new))

    categories =
      issues_to_display
      |> Enum.map(& &1.category)
      |> Enum.uniq()

    issue_map =
      Enum.into(categories, %{}, fn category ->
        {category, Enum.filter(issues_to_display, &(&1.category == category))}
      end)

    source_file_map = Enum.into(source_files, %{}, &{&1.filename, &1})

    categories
    |> Sorter.ensure(@category_starting_order, @category_ending_order)
    |> Enum.each(fn category ->
      print_issues_for_category(
        category,
        issue_map[category],
        source_file_map,
        exec,
        term_width
      )
    end)

    DiffSummary.print(source_files, exec, time_load, time_run)
  end

  defp print_issues_for_category(
         _category,
         nil,
         _source_file_map,
         _exec,
         _term_width
       ) do
    nil
  end

  defp print_issues_for_category(
         category,
         issues,
         source_file_map,
         exec,
         term_width
       ) do
    color = @category_colors[category] || :magenta
    title = @category_titles[category] || "Category: #{category}"

    UI.puts()

    [
      diff_marker(1, color),
      :bright,
      "#{color}_background" |> String.to_atom(),
      color,
      " ",
      Output.foreground_color(color),
      :normal,
      " #{title}" |> String.pad_trailing(term_width - 3)
    ]
    |> UI.puts()

    UI.puts([
      diff_marker(2, color),
      UI.edge(color)
    ])

    print_issues(issues, source_file_map, exec, term_width)

    if Enum.count(issues) > per_category(exec) do
      not_shown = Enum.count(issues) - per_category(exec)

      [
        diff_marker(),
        UI.edge(color),
        :faint,
        " ...  (#{not_shown} other new issues, use `--all` to show them)"
      ]
      |> UI.puts()
    end
  end

  defp print_issues(issues, source_file_map, exec, term_width) do
    count = per_category(exec)
    sort_weight = %{old: 2, fixed: 1, new: 0}

    issues
    |> Enum.sort_by(fn issue ->
      {sort_weight[issue.diff_marker], issue.priority, issue.severity, issue.filename,
       issue.line_no}
    end)
    |> Enum.reverse()
    |> Enum.take(count)
    |> do_print_issues(source_file_map, exec, term_width)
  end

  defp per_category(%Execution{all: true}), do: 1_000_000
  defp per_category(%Execution{all: false}), do: @per_category

  defp do_print_issues(
         issues,
         source_file_map,
         %Execution{format: _} = exec,
         term_width
       ) do
    Enum.each(issues, fn %Issue{filename: filename} = issue ->
      source_file = source_file_map[filename]

      do_print_issue(issue, source_file, exec, term_width)
    end)
  end

  defp do_print_issue(
         %Issue{
           check: check,
           message: message,
           filename: filename,
           priority: priority
         } = issue,
         source_file,
         %Execution{format: _, verbose: verbose} = exec,
         term_width
       ) do
    new_issue? = issue.diff_marker == :new
    fixed_issue? = issue.diff_marker == :fixed

    outer_color =
      if new_issue? do
        Output.check_color(issue)
      else
        [Output.check_color(issue), :faint]
      end

    inner_color =
      if new_issue? do
        Output.issue_color(issue)
      else
        [Output.issue_color(issue), :faint]
      end

    message_color = outer_color
    filename_color = :default_color

    tag_style =
      if outer_color == inner_color do
        :faint
      else
        :bright
      end

    message =
      if verbose do
        message <> " (" <> inspect(check) <> ")"
      else
        message
      end

    message
    |> UI.wrap_at(term_width - @indent)
    |> print_issue_message(
      issue,
      check,
      outer_color,
      message_color,
      tag_style,
      priority
    )

    location =
      if fixed_issue? do
        git_ref = Execution.get_assign(exec, "credo.diff.previous_git_ref")
        previous_dirname = Execution.get_assign(exec, "credo.diff.previous_dirname")

        relative_filename =
          filename |> String.replace(previous_dirname, "") |> String.replace(~r/^[\/\\]/, "")

        "(git:#{git_ref}) #{relative_filename}"
      else
        to_string(filename)
      end

    [
      diff_marker(issue.diff_marker),
      UI.edge(outer_color, @indent),
      filename_color,
      :faint,
      location,
      :default_color,
      :faint,
      Filename.pos_suffix(issue.line_no, issue.column),
      :conceal,
      " #",
      :reset,
      :faint,
      "(#{issue.scope})"
    ]
    |> UI.puts()

    if exec.verbose && issue.diff_marker == :new do
      print_issue_line(issue, source_file, inner_color, outer_color, term_width)

      [
        diff_marker(issue.diff_marker),
        UI.edge([
          outer_color,
          :faint
        ])
      ]
      |> UI.puts()
    end
  end

  defp print_issue_message(
         [first_line | other_lines],
         issue,
         check,
         outer_color,
         message_color,
         tag_style,
         priority
       ) do
    [
      diff_marker(issue.diff_marker),
      UI.edge(outer_color),
      outer_color,
      tag_style,
      Output.check_tag(check.category),
      " ",
      priority |> Output.priority_arrow(),
      :normal,
      message_color,
      " ",
      first_line
    ]
    |> UI.puts()

    other_lines
    |> Enum.each(&print_issue_message(&1, issue, outer_color, message_color))
  end

  defp print_issue_message(
         "",
         _issue,
         _outer_color,
         _message_color
       ) do
  end

  defp print_issue_message(
         message,
         issue,
         outer_color,
         message_color
       ) do
    [
      diff_marker(issue.diff_marker),
      UI.edge(outer_color),
      outer_color,
      String.duplicate(" ", @indent - 3),
      :normal,
      message_color,
      " ",
      message
    ]
    |> UI.puts()
  end

  defp print_issue_line(
         %Issue{line_no: nil},
         _source_file,
         _inner_color,
         _outer_color,
         _term_width
       ) do
    nil
  end

  defp print_issue_line(
         %Issue{} = issue,
         source_file,
         inner_color,
         outer_color,
         term_width
       ) do
    raw_line = SourceFile.line_at(source_file, issue.line_no)
    line = String.trim(raw_line)

    [diff_marker(issue.diff_marker), UI.edge([outer_color, :faint])]
    |> UI.puts()

    [
      diff_marker(issue.diff_marker),
      UI.edge([outer_color, :faint]),
      :cyan,
      :faint,
      String.duplicate(" ", @indent - 2),
      UI.truncate(line, term_width - @indent)
    ]
    |> UI.puts()

    print_issue_trigger_marker(issue, raw_line, inner_color, outer_color)
  end

  defp print_issue_trigger_marker(
         %Issue{column: nil},
         _line,
         _inner_color,
         _outer_color
       ) do
    nil
  end

  defp print_issue_trigger_marker(
         %Issue{} = issue,
         line,
         inner_color,
         outer_color
       ) do
    offset = String.length(line) - String.length(String.trim(line))

    # column is one-based
    x = max(issue.column - offset - 1, 0)

    w =
      case issue.trigger do
        nil -> 1
        atom -> atom |> to_string |> String.length()
      end

    [
      diff_marker(issue.diff_marker),
      UI.edge([outer_color, :faint], @indent),
      inner_color,
      String.duplicate(" ", x),
      :faint,
      String.duplicate("^", w)
    ]
    |> UI.puts()
  end

  defp diff_marker() do
    [:faint, "  ", :reset, ""]
  end

  defp diff_marker(1, color) do
    [color, :faint, "  ", :reset, ""]
  end

  defp diff_marker(2, color) do
    [color, :faint, "  ", :reset, ""]
  end

  defp diff_marker(:new) do
    [:green, :bright, "+ ", :reset, ""]
  end

  defp diff_marker(:old) do
    [:faint, "~ ", :reset, ""]
  end

  defp diff_marker(:fixed) do
    [:faint, "✔ ", :reset, ""]
  end
end
