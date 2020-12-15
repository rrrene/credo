defmodule Credo.Execution.Task.DetermineCommand do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.CLI.Options
  alias Credo.Execution

  def call(exec, _opts) do
    determine_command(exec, exec.cli_options)
  end

  # `--help` given
  defp determine_command(
         exec,
         %Options{command: nil, switches: %{help: true}} = options
       ) do
    set_command_and_path(exec, options, "help", options.path)
  end

  # `--version` given
  defp determine_command(
         exec,
         %Options{command: nil, switches: %{version: true}} = options
       ) do
    set_command_and_path(exec, options, "version", options.path)
  end

  defp determine_command(exec, options) do
    command_name =
      case exec.cli_options.args do
        [potential_command_name | _] ->
          command_names = Execution.get_valid_command_names(exec)

          if Enum.member?(command_names, potential_command_name) do
            potential_command_name
          end

        _ ->
          nil
      end

    set_command_and_path(exec, options, command_name, options.path)
  end

  defp set_command_and_path(exec, _options, nil, _path), do: exec

  defp set_command_and_path(exec, options, command, path) do
    %Execution{
      exec
      | cli_options: %Options{
          options
          | command: command,
            path: path
        }
    }
  end
end
