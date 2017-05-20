defmodule Credo.Execution.Task.HaltIfExitStatusAssigned do
  use Credo.Execution.Task

  def call(%Execution{mute_exit_status: true} = exec, _opts) do
    # Skip if exit status is muted
    exec
  end
  def call(exec, _opts) do
    exec
    |> get_assign("credo.exit_status", 0)
    |> halt_if_failed()

    exec
  end

  defp halt_if_failed(0), do: nil
  defp halt_if_failed(x), do: System.halt(x)
end
