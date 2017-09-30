defmodule Credo.Execution.Task.DetermineCommand do
  use Credo.Execution.Task

  alias Credo.CLI.Options

  def call(exec, _opts) do
    exec
    |> determine_command(exec.cli_options)
  end

  defp determine_command(%Execution{help: true} = exec, %Options{command: nil} = options) do
    set_command_and_path(exec, options, "help", options.path)
  end
  defp determine_command(%Execution{version: true} = exec, %Options{command: nil} = options) do
    set_command_and_path(exec, options, "version", options.path)
  end
  defp determine_command(exec, _options), do: exec

  defp set_command_and_path(exec, options, command, path) do
    %Execution{
      exec |
      cli_options: %Options{
        options |
        command: command,
        path: path
      }
    }
  end
end
