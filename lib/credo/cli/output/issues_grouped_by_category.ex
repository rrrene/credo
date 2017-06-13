defmodule Credo.CLI.Output.IssuesGroupedByCategory do
  alias Credo.CLI.Filter
  alias Credo.CLI.Output
  alias Credo.CLI.Output.IssueHelper
  alias Credo.CLI.Output.UI
  alias Credo.CLI.Output.Summary
  alias Credo.CLI.Sorter
  alias Credo.Execution

  @category_starting_order [:design, :readability, :refactor]
  @category_ending_order [:warning, :consistency, :custom, :unknown]
  @category_colors [
    design: :olive,
    readability: :blue,
    refactor: :yellow,
    warning: :red,
    consistency: :cyan,
  ]
  @category_titles [
    design: "Software Design",
    readability: "Code Readability",
    refactor: "Refactoring opportunities",
    warning: "Warnings - please take a look",
    consistency: "Consistency",
  ]
  @many_source_files 60
  @per_category 5
  @valid_formats ~w(flycheck oneline)

  @doc "Called before the analysis is run."
  def print_before_info(_source_files, %Execution{format: format}) when format in @valid_formats do
    :ok
  end
  def print_before_info(source_files, exec) do
    case Enum.count(source_files) do
      0 -> UI.puts "No files found!"
      1 -> UI.puts "Checking 1 source file ..."
      count -> UI.puts "Checking #{count} source files#{checking_suffix(count)} ..."
    end

    Output.print_skipped_checks(exec)
  end

  defp checking_suffix(count) when count > @many_source_files do
    " (this might take a while)"
  end
  defp checking_suffix(_), do: ""

  @doc "Called after the analysis has run."
  def print_after_info(source_files, exec, time_load, time_run) do
    term_width = Output.term_columns

    issues = Credo.Execution.get_issues(exec)

    shown_issues =
      issues
      |> Filter.important(exec)
      |> Filter.valid_issues(exec)

    categories =
      shown_issues
      |> Enum.map(&(&1.category))
      |> Enum.uniq

    issue_map =
      categories
      |> Enum.map(fn(category) ->
          {category, shown_issues |> Enum.filter(&(&1.category == category))}
        end)
      |> Enum.into(%{})

    source_file_map =
      source_files
      |> Enum.map(&({&1.filename, &1}))
      |> Enum.into(%{})

    categories
    |> Sorter.ensure(@category_starting_order, @category_ending_order)
    |> Enum.each(fn(category) ->
        print_issues_for_category(category, issue_map[category], source_file_map, exec, term_width)
      end)

    source_files
    |> Summary.print(exec, time_load, time_run)
  end

  defp print_issues_for_category(_category, nil, _source_file_map, _exec, _term_width) do
    nil
  end
  defp print_issues_for_category(_category, issues, source_file_map, %Execution{format: format} = exec, term_width)
        when not is_nil(format) and format in @valid_formats do
    print_issues(issues, source_file_map, exec, term_width)
  end
  defp print_issues_for_category(_category, issues, source_file_map, %Execution{format: "oneline"} = exec, term_width) do
    print_issues(issues, source_file_map, exec, term_width)
  end
  defp print_issues_for_category(category, issues, source_file_map, exec, term_width) do
    color = @category_colors[category] || :magenta
    title = @category_titles[category] || "Category: #{category}"

    UI.puts

    [
      :bright, "#{color}_background" |> String.to_atom, color, " ",
        Output.foreground_color(color), :normal,
      " #{title}" |> Credo.Backports.String.pad_trailing(term_width - 1),
    ]
    |> UI.puts

    color
    |> UI.edge
    |> UI.puts

    print_issues(issues, source_file_map, exec, term_width)

    if Enum.count(issues) > per_category(exec) do
      not_shown = Enum.count(issues) - per_category(exec)

      [UI.edge(color), :faint, " ...  (#{not_shown} more, use `-a` to show them)"]
      |> UI.puts
    end
  end

  defp print_issues(issues, source_file_map, exec, term_width) do
    count = per_category(exec)

    issues
    |> Enum.sort_by(fn(issue) ->
        {issue.priority, issue.severity, issue.filename, issue.line_no}
      end)
    |> Enum.reverse
    |> Enum.take(count)
    |> IssueHelper.print_issues(source_file_map, exec, term_width)
  end

  def per_category(%Execution{all: true}), do: 1_000_000
  def per_category(%Execution{all: false}), do: @per_category

end
