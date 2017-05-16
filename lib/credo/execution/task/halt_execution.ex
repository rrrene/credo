defmodule Credo.Execution.Task.HaltExecution do
  use Credo.Execution.Task
  use Bitwise

  def call(exec, _opts) do
    exit_status =
      exec
      |> get_result("issues", [])
      |> to_exit_status()

    halt_if_failed(exit_status)

    exec
  end

  # Converts the return value of a Command.run() call into an exit_status
  defp to_exit_status([]), do: 0
  defp to_exit_status(issues) do
    issues
    |> Enum.map(&(&1.exit_status))
    |> Enum.reduce(0, &(&1 ||| &2))
  end

  defp halt_if_failed(0), do: nil
  defp halt_if_failed(x), do: System.halt(x)
end
