defmodule Credo.CLI.Command.Diff.Task.FilterIssuesTest do
  use Credo.Test.Case

  alias Credo.CLI.Command.Diff.Task.FilterIssues
  alias Credo.Execution
  alias Credo.Issue

  test "Filter issue should return none fixed issues" do
    current_issues = [
      %Issue{
        filename: "lib/random/application.ex",
        line_no: 2,
        column: 1
      }
    ]

    previous_issues = [
      %Issue{
        filename: "random_dir_name/lib/random/application.ex",
        line_no: 2,
        column: 1
      }
    ]

    prev_exec = Execution.put_issues(Execution.build(), previous_issues)

    exec =
      Execution.build()
      |> Execution.put_assign("credo.diff.previous_exec", prev_exec)
      |> Execution.put_assign("credo.diff.previous_dirname", "random_dir_name")
      |> Execution.put_issues(current_issues)

    result_exec = FilterIssues.call(exec, [])

    result_issues = Execution.get_issues(result_exec)

    assert [_issue] = Enum.filter(result_issues, fn issue -> issue.diff_marker == :old end)
    assert [] = Enum.filter(result_issues, fn issue -> issue.diff_marker == :fixed end)
  end

  test "Filter issue should return fixed issues" do
    current_issues = []

    previous_issues = [
      %Issue{
        filename: "random_dir_name/lib/random/application.ex",
        line_no: 2,
        column: 1
      }
    ]

    prev_exec = Execution.put_issues(Execution.build(), previous_issues)

    exec =
      Execution.build()
      |> Execution.put_assign("credo.diff.previous_exec", prev_exec)
      |> Execution.put_assign("credo.diff.previous_dirname", "random_dir_name")
      |> Execution.put_issues(current_issues)

    result_exec = FilterIssues.call(exec, [])

    result_issues = Execution.get_issues(result_exec)

    assert [] = Enum.filter(result_issues, fn issue -> issue.diff_marker == :old end)
    assert [_issue] = Enum.filter(result_issues, fn issue -> issue.diff_marker == :fixed end)
  end
end
