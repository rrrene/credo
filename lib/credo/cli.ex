defmodule Credo.CLI do
  @moduledoc """
  `Credo.CLI` is the entrypoint for both the Mix task and the escript.
  """

  alias Credo.Execution
  alias Credo.Execution.Task.WriteDebugReport

  @doc """
  Runs Credo with the given `argv` and exits the process.

  See `run/1` if you want to run Credo programmatically.
  """
  def main(argv \\ []) do
    Credo.Application.start(nil, nil)

    argv
    |> run()
    |> halt_if_exit_status_assigned()
  end

  @doc """
  Runs Credo with the given `argv` and returns its final `Credo.Execution` struct.

  Example:

      iex> exec = Credo.CLI.run(["--only", "Readability"])
      iex> issues = Credo.Execution.get_issues(exec)
      iex> Enum.count(issues) > 0
      true

  """
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
  defp halt_if_failed(exit_status), do: exit({:shutdown, exit_status})
end
