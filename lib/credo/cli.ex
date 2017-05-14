defmodule Credo.CLI do
  @moduledoc """
  Credo.CLI is the entrypoint for both the Mix task and the escript.

  It takes the parameters passed from the command line and translates them into
  a Command module (see the `Credo.CLI.Command` namespace), the work directory
  where the Command should run and a `Credo.Execution` object.
  """

  use Bitwise

  alias Credo.Execution
  alias Credo.ConfigBuilder
  alias Credo.Sources
  alias Credo.CLI.Filename
  alias Credo.CLI.Options
  alias Credo.CLI.Output.UI
  alias Credo.Service.Commands

  @default_command_name "suggest"

  @doc false
  def main(argv) do
    Credo.start nil, nil

    argv
    |> run()
    |> to_exit_status()
    |> halt_if_failed()
  end

  defp run(argv) when is_list(argv) do
    argv
    |> parse_options()
    |> run()
  end
  defp run({:ok, command_mod, _dir, exec}) do
    exec
    |> UI.use_colors
    |> Credo.CheckForUpdates.run
    |> require_requires()
    |> command_mod.run
  end
  defp run({:error, options, exec}) do
    UI.use_colors(exec)

    Enum.each(options.unknown_args, &print_argument/1)
    Enum.each(options.unknown_switches, &print_switch/1)

    :error
  end

  defp print_argument(name) do
    UI.warn [:red, "Unknown argument: #{name}"]
  end

  defp print_switch({name, _value}), do: print_switch(name)
  defp print_switch(name) do
    UI.warn [:red, "Unknown switch: #{name}"]
  end

  # Requires the additional files specified in the exec.
  defp require_requires(%Execution{requires: requires} = exec) do
    requires
    |> Sources.find
    |> Enum.each(&Code.require_file/1)

    exec
  end

  defp parse_options(argv) when is_list(argv) do
    options = Options.parse(argv, File.cwd!, Commands.names, [UI.edge])
    exec =
      options
      |> ConfigBuilder.parse
      |> start_servers()

    options
    |> set_command_in_options(exec)
    |> validate_options(exec)
  end

  defp start_servers(%Execution{} = exec) do
    exec
    |> Credo.Execution.SourceFiles.start_server
    |> Credo.Execution.Issues.start_server
  end

  defp validate_options(%Options{unknown_args: [], unknown_switches: []} = options, exec) do
    {:ok, command_for(options.command), options.path, exec}
  end
  defp validate_options(options, exec) do
    {:error, options, exec}
  end

  defp set_command_in_options(%Options{command: nil} = options, %Execution{help: true}) do
    %Options{options | command: "help"}
  end
  defp set_command_in_options(%Options{command: nil} = options, %Execution{version: true}) do
    %Options{options | command: "version"}
  end
  defp set_command_in_options(%Options{command: nil, args: args} = options, _config) do
    potential_path = List.first(args)

    if Filename.contains_line_no?(potential_path) do
      %Options{options | command: "explain", path: potential_path}
    else
      %Options{options | command: @default_command_name}
    end
  end
  defp set_command_in_options(options, _config), do: options

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

  # Converts the return value of a Command.run() call into an exit_status
  defp to_exit_status(:ok), do: 0
  defp to_exit_status(:error), do: 255
  defp to_exit_status({:error, issues}) do
    issues
    |> Enum.map(&(&1.exit_status))
    |> Enum.reduce(0, &(&1 ||| &2))
  end

  defp halt_if_failed(0), do: nil
  defp halt_if_failed(x), do: System.halt(x)
end
