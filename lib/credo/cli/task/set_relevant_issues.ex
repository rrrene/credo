defmodule Credo.CLI.Task.SetRelevantIssues do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.CLI.Filter

  def call(exec, _opts \\ []) do
    issues =
      exec
      |> get_issues()
      |> Filter.important(exec)
      |> Filter.valid_issues(exec)
      |> Enum.sort_by(fn issue ->
        {issue.check.id(), issue.filename, issue.line_no}
      end)

    put_issues(exec, issues)
  end
end
