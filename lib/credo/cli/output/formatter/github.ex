defmodule Credo.CLI.Output.Formatter.GitHub do
  @moduledoc false

  alias Credo.CLI.Filename
  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI
  alias Credo.Issue

  def print_issues(issues) do
    issues
    |> Enum.group_by(& &1.filename)
    |> Enum.flat_map(&to_github_group/1)
    |> Enum.each(&UI.puts/1)
  end

  def to_github_group({filename, issues}) do
    count = length(issues)
    count_issues = if count == 1, do: "1 issue", else: "#{count} issues"

    ["::group::#{count_issues} in #{filename}"] ++
      Enum.flat_map(issues, &to_github/1) ++
      ["::endgroup::"]
  end

  def to_github(
        %Issue{
          message: message,
          filename: filename,
          column: column,
          line_no: line_no
        } = issue
      ) do
    category = issue.category |> to_string() |> String.capitalize()
    arrow = issue.priority |> Output.priority_arrow()
    pos_suffix = Filename.pos_suffix(line_no, column)

    [
      "::error file=#{filename},line=#{line_no},col=#{column}::#{message} [#{arrow} #{category}]",
      "  at #{filename}#{pos_suffix}"
    ]
  end
end
