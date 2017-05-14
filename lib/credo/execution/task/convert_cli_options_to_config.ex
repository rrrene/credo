defmodule Credo.Execution.Task.ConvertCLIOptionsToConfig do
  use Credo.Execution.Task

  alias Credo.CLI.Options
  alias Credo.ConfigBuilder
  alias Credo.CLI.Filename

  @default_command_name "suggest"

  def call(exec, _opts) do
    exec = ConfigBuilder.parse(exec.cli_options)

    exec
    |> determine_command(exec.cli_options)
    |> start_servers()
  end

  defp start_servers(%Execution{} = exec) do
    exec
    |> Credo.Execution.SourceFiles.start_server
    |> Credo.Execution.Issues.start_server
  end

  defp determine_command(%Execution{help: true} = exec, %Options{command: nil} = options) do
    set_command_and_path(exec, options, "help", options.path)
  end
  defp determine_command(%Execution{version: true} = exec, %Options{command: nil} = options) do
    set_command_and_path(exec, options, "version", options.path)
  end
  defp determine_command(exec, %Options{command: nil, args: args} = options) do
    potential_path = List.first(args)

    if Filename.contains_line_no?(potential_path) do
      set_command_and_path(exec, options, "explain", potential_path)
    else
      set_command_and_path(exec, options, @default_command_name, options.path)
    end
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
