defmodule Credo.CLI.Output.Formatter.GitHub do
  @moduledoc false

  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI
  alias Credo.Issue

  def print_issues(issues) do
    Enum.each(issues, fn issue ->
      issue
      |> to_github()
      |> UI.puts()
    end)
  end

  def to_github(
        %Issue{
          message: message,
          filename: filename,
          column: column,
          line_no: line_no,
          priority: priority
        } = issue
      ) do
    tag = Output.check_tag(issue, false)
    priority = priority |> Output.priority_arrow()

    "::error file=#{filename},line=#{line_no},col=#{column}::#{tag} #{priority} #{message}"
  end
end
