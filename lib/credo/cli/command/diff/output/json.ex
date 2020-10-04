defmodule Credo.CLI.Command.Diff.Output.Json do
  @moduledoc false

  alias Credo.CLI.Output.Formatter.JSON
  alias Credo.Execution

  def print_before_info(_source_files, _exec), do: nil

  def print_after_info(_source_files, exec, _time_load, _time_run) do
    issues = Execution.get_issues(exec)
    new_issues = Enum.filter(issues, &(&1.diff_marker == :new))
    fixed_issues = Enum.filter(issues, &(&1.diff_marker == :fixed))
    old_issues = Enum.filter(issues, &(&1.diff_marker == :old))

    %{
      "diff" => %{
        "new" => Enum.map(new_issues, &JSON.issue_to_json/1),
        "fixed" => Enum.map(fixed_issues, &JSON.issue_to_json/1),
        "old" => Enum.map(old_issues, &JSON.issue_to_json/1)
      }
    }
    |> JSON.print_map()
  end
end
