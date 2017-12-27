defmodule Credo.CLI.Output.IssuesGroupedByCategory.Oneline do
  alias Credo.Execution
  alias Credo.CLI.Filename
  alias Credo.Issue
  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI

  def print_before_info(_source_files, _exec), do: nil

  def print_after_info(source_files, exec, _time_load, _time_run) do
    term_width = Output.term_columns

    issues = Credo.Execution.get_issues(exec)

    source_file_map =
      source_files
      |> Enum.map(&({&1.filename, &1}))
      |> Enum.into(%{})

    print_issues(issues, source_file_map, exec, term_width)
  end

  def print_issues(issues, source_file_map, %Execution{format: _} = exec, term_width) do
    Enum.each(issues, fn(%Issue{filename: filename} = issue) ->
      source_file = source_file_map[filename]

      do_print_issue(issue, source_file, exec, term_width)
    end)
  end

  def do_print_issue(%Issue{check: check, message: message, filename: filename, priority: priority} = issue, _source_file, _exec, _term_width) do
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
end
