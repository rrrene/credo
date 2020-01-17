defmodule Credo.CLI do
  @moduledoc """
  `Credo.CLI` is the entrypoint for both the Mix task and the escript.

  It takes the parameters passed from the command line and translates them into
  a Command module (see the `Credo.CLI.Command` namespace), the work directory
  where the Command should run and a `Credo.Execution` struct.
  """

  alias Credo.Execution
  alias Credo.Execution.Task.WriteDebugReport

  @doc """
  Runs Credo's main process.
  """
  def main(argv \\ []) do
    Credo.Application.start(nil, nil)

    argv
    |> run()
    |> halt_if_exit_status_assigned()
  end

  def run(argv) do
    argv
    |> Execution.build()
    |> Execution.run()
    |> WriteDebugReport.call([])
  end

  defp halt_if_exit_status_assigned(%Execution{mute_exit_status: true}) do
    # Skip if exit status is muted
  end

  defp halt_if_exit_status_assigned(exec) do
    exec
    |> Execution.get_assign("credo.exit_status", 0)
    |> halt_if_failed()
  end

  defp halt_if_failed(0), do: nil
  defp halt_if_failed(x), do: System.halt(x)
end
