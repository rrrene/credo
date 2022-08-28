defmodule Credo.Execution.Task.AssignExitStatusForIssues do
  @moduledoc false

  use Credo.Execution.Task

  import Bitwise

  def call(exec, _opts) do
    exit_status =
      exec
      |> get_issues()
      |> to_exit_status()

    put_exit_status(exec, exit_status)
  end

  # Converts the return value of a Command.run() call into an exit_status
  defp to_exit_status([]), do: 0

  defp to_exit_status(issues) do
    issues
    |> Enum.map(& &1.exit_status)
    |> Enum.reduce(0, &(&1 ||| &2))
  end
end
