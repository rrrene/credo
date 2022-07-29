defmodule Credo.CLI.Command.Diff.Task.FilterIssues do
  use Credo.Execution.Task

  alias Credo.Issue

  def call(exec, _opts) do
    issues = get_old_new_and_fixed_issues(exec)

    Execution.put_issues(exec, issues)
  end

  defp get_old_new_and_fixed_issues(exec) do
    current_issues = Execution.get_issues(exec)

    previous_issues =
      exec
      |> Execution.get_assign("credo.diff.previous_exec")
      |> Execution.get_issues()

    previous_dirname = Execution.get_assign(exec, "credo.diff.previous_dirname")

    # in previous_issues, in current_issues
    old_issues = Enum.filter(current_issues, &old_issue?(&1, previous_issues, previous_dirname))

    # in previous_issues, not in current_issues
    fixed_issues = previous_issues -- old_issues

    # not in previous_issues, in current_issues
    new_issues = Enum.filter(current_issues, &new_issue?(&1, previous_issues, previous_dirname))

    old_issues = Enum.map(old_issues, fn issue -> %Issue{issue | diff_marker: :old} end)

    # TODO: we have to rewrite the filename to make it look like the file is in the current dir
    #       instead of the generated tmp dir
    fixed_issues = Enum.map(fixed_issues, fn issue -> %Issue{issue | diff_marker: :fixed} end)
    new_issues = Enum.map(new_issues, fn issue -> %Issue{issue | diff_marker: :new} end)

    List.flatten([new_issues, fixed_issues, old_issues])
  end

  defp new_issue?(current_issue, previous_issues, previous_dirname)
       when is_list(previous_issues) do
    !Enum.any?(previous_issues, &same_issue?(current_issue, &1, previous_dirname))
  end

  defp old_issue?(previous_issue, current_issues, previous_dirname)
       when is_list(current_issues) do
    Enum.any?(current_issues, &same_issue?(previous_issue, &1, previous_dirname))
  end

  defp same_issue?(current_issue, %Issue{} = previous_issue, previous_dirname) do
    same_file_or_same_line? =
      current_issue.filename == Path.relative_to(previous_issue.filename, previous_dirname) ||
        current_issue.line_no == previous_issue.line_no

    same_file_or_same_line? &&
      current_issue.column == previous_issue.column &&
      current_issue.category == previous_issue.category &&
      current_issue.message == previous_issue.message &&
      current_issue.trigger == previous_issue.trigger &&
      current_issue.scope == previous_issue.scope
  end
end
