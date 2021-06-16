defmodule Credo.CLI.Command.Diff.Task.FilterIssuesForExitStatus do
  @moduledoc false

  use Credo.Execution.Task

  def call(exec, _opts) do
    issues =
      exec
      |> Execution.get_issues()
      |> Enum.filter(fn
        %Credo.Issue{diff_marker: :new} -> true
        _ -> false
      end)

    Execution.put_issues(exec, issues)
  end
end
