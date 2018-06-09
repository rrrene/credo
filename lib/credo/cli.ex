defmodule Credo.CLI do
  @moduledoc """
  `Credo.CLI` is the entrypoint for both the Mix task and the escript.

  It takes the parameters passed from the command line and translates them into
  a Command module (see the `Credo.CLI.Command` namespace), the work directory
  where the Command should run and a `Credo.Execution` struct.
  """

  alias Credo.Execution
  alias Credo.Execution.Task.WriteDebugReport
  alias Credo.MainProcess
  alias Credo.Service.Commands

  @doc """
  Runs Credo's main process.
  """
  def main(argv) do
    Credo.Application.start(nil, nil)

    %Execution{argv: argv}
    |> MainProcess.call()
    |> WriteDebugReport.call([])
    |> halt_if_exit_status_assigned()
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

  @doc """
  Returns the module of a given `command`.

      iex> command_for(:help)
      Credo.CLI.Command.Help
  """
  def command_for(nil), do: nil

  def command_for(command_mod) when is_atom(command_mod) do
    if Enum.member?(Commands.modules(), command_mod) do
      command_mod
    else
      nil
    end
  end

  def command_for(command_name) when is_binary(command_name) do
    if Enum.member?(Commands.names(), command_name) do
      Commands.get(command_name)
    else
      nil
    end
  end
end
