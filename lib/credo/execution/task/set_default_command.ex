defmodule Credo.Execution.Task.SetDefaultCommand do
  @moduledoc false

  @default_command_name "suggest"
  @explain_command_name "explain"

  use Credo.Execution.Task

  alias Credo.CLI.Filename
  alias Credo.CLI.Options

  def call(exec, _opts) do
    determine_command(exec, exec.cli_options)
  end

  defp determine_command(exec, %Options{command: nil, args: args} = options) do
    potential_path = List.first(args)

    if Filename.contains_line_no?(potential_path) do
      set_command_and_path(exec, options, @explain_command_name, potential_path)
    else
      set_command_and_path(exec, options, @default_command_name, options.path)
    end
  end

  defp determine_command(exec, _options), do: exec

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
