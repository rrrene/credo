defmodule Credo.CLI do
  @moduledoc """
  Credo.CLI is the entrypoint for both the Mix task and the escript.

  It takes the parameters passed from the command line and translates them into
  a Command module (see the `Credo.CLI.Command` namespace), the work directory
  where the Command should run and a `Credo.Execution` object.
  """

  alias Credo.Execution
  alias Credo.Service.Commands

  @doc false
  def main(argv) do
    Credo.start nil, nil

    %Execution{argv: argv}
    |> Credo.Execution.Task.run(Credo.Execution.Task.ParseOptions)
    |> Credo.Execution.Task.run(Credo.Execution.Task.ValidateOptions)
    |> Credo.Execution.Task.run(Credo.Execution.Task.ConvertCLIOptionsToConfig)
    |> Credo.Execution.Task.run(Credo.Execution.Task.ValidateConfig)
    |> Credo.Execution.Task.run(Credo.Execution.Task.ResolveConfig)
    |> Credo.Execution.Task.run(Credo.Execution.Task.RunCommand)
    |> Credo.Execution.Task.run(Credo.Execution.Task.HaltExecution)
  end

  @doc """
  Returns the module of a given `command`.

      iex> command_for(:help)
      Credo.CLI.Command.Help
  """
  def command_for(nil), do: nil
  def command_for(command_mod) when is_atom(command_mod) do
    if Enum.member?(Commands.modules, command_mod) do
      command_mod
    else
      nil
    end
  end
  def command_for(command_name) when is_binary(command_name) do
    if Enum.member?(Commands.names, command_name) do
      Commands.get(command_name)
    else
      nil
    end
  end
end
