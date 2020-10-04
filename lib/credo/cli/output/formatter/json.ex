defmodule Credo.CLI.Output.Formatter.JSON do
  @moduledoc false

  alias Credo.CLI.Output.UI
  alias Credo.Issue

  def print_issues(issues) do
    %{
      "issues" => Enum.map(issues, &issue_to_json/1)
    }
    |> print_map()
  end

  def print_map(map) do
    UI.puts(Jason.encode!(map, pretty: true))
  end

  def issue_to_json(
        %Issue{
          check: check,
          category: category,
          message: message,
          filename: filename,
          priority: priority,
          scope: scope
        } = issue
      ) do
    check_name =
      check
      |> to_string()
      |> String.replace(~r/^(Elixir\.)/, "")

    column_end =
      if issue.column && issue.trigger do
        issue.column + String.length(to_string(issue.trigger))
      end

    %{
      "check" => check_name,
      "category" => to_string(category),
      "filename" => to_string(filename),
      "line_no" => issue.line_no,
      "column" => issue.column,
      "column_end" => column_end,
      "trigger" => issue.trigger,
      "message" => message,
      "priority" => priority,
      "scope" => scope
    }
  end
end
