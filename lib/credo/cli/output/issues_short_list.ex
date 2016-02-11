defmodule Credo.CLI.Output.IssuesShortList do
  alias Credo.CLI.Filename
  alias Credo.CLI.Filter
  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI
  alias Credo.SourceFile
  alias Credo.Issue

  @indent 8

  @doc "Called before the analysis is run."
  def print_before_info(source_files, _config) do
    case Enum.count(source_files) do
      0 -> UI.puts "No files found!"
      _ -> :ok
    end
  end

  @doc "Called after the analysis has run."
  def print_after_info(source_files, config, _time_load, _time_run) do
    term_width = Output.term_columns

    source_files
    |> Enum.sort_by(&(&1.filename))
    |> Enum.each(&print_issues(&1, config, term_width))
  end

  defp print_issues(%SourceFile{issues: issues, filename: filename} = source_file, config, term_width) do
    issues
    |> Filter.important(config)
    |> Filter.valid_issues(config)
    |> print_issues(filename, source_file, config, term_width)
  end

  defp print_issues(issues, _filename, source_file, _config, term_width) do
    issues
    |> Enum.sort_by(&(&1.line_no))
    |> Enum.each(&print_issue(&1, source_file, term_width))
  end

  defp print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, _source_file, _term_width) do
    outer_color = Output.check_color(issue)
    inner_color = Output.check_color(issue)
    message_color  = inner_color
    filename_color = :default_color

    [
      inner_color,
      check_tag_style(outer_color, inner_color),
      Output.check_tag(check.category), " ", priority |> Output.priority_arrow, " ",
      :reset, filename_color, :faint, filename |> to_string,
      :default_color, :faint, Filename.pos_suffix(issue.line_no, issue.column),
      :reset, message_color,  " ", message,
    ]
    |> UI.puts
  end

  defp check_tag_style(a, a), do: :faint
  defp check_tag_style(_a, _b), do: :bright
end
