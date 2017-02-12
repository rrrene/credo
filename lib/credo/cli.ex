defmodule Credo.CLI do
  @moduledoc """
  Credo.CLI is the entrypoint for both the Mix task and the escript.

  It takes the parameters passed from the command line and translates them into
  a Command module (see the `Credo.CLI.Command` namespace), the work directory
  where the Command should run and a `Credo.Config` object.
  """

  use Bitwise

  alias Credo.Config
  alias Credo.ConfigBuilder
  alias Credo.Sources
  alias Credo.CLI.Filename
  alias Credo.CLI.Options
  alias Credo.CLI.Output.UI
  alias Credo.Service.Commands

  @default_dir "."
  @default_command_name "suggest"

  @doc false
  def main(argv) do
    Credo.start nil, nil

    argv
    |> run()
    |> to_exit_status()
    |> halt_if_failed()
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

  defp run(argv) when is_list(argv) do
    argv
    |> parse_options()
    |> run()
  end
  defp run({:ok, command_mod, dir, config}) do
    UI.use_colors(config.color)

    if config.check_for_updates, do: Credo.CheckForUpdates.run()

    require_requires(config)

    command_mod.run(config)
  end
  defp run({:error, options, config}) do
    UI.use_colors(config.color)

    if options.unknown_args != [] do
      options.unknown_args
      |> Enum.each(&print_switch(&1, "argument"))
    end

    if options.unknown_switches != [] do
      options.unknown_switches
      |> Enum.each(&print_switch(&1, "switch"))
    end

    :error
  end

  defp print_switch({name, _value}, type), do: print_switch(name, type)
  defp print_switch(name, type) do
    UI.warn [:red, "Unknown #{type}: #{name}"]
  end

  # Requires the additional files specified in the config.
  defp require_requires(%Config{requires: requires}) do
    requires
    |> Sources.find
    |> Enum.each(&Code.require_file/1)
  end

  defp parse_options(argv) when is_list(argv) do
    options = Options.parse(argv, File.cwd!, Commands.names)
    config = ConfigBuilder.parse(options)

    options
    |> set_command_in_options(config)
    |> validate_options(config)
  end

  defp validate_options(%Options{unknown_args: [], unknown_switches: []} = options, config) do
    {:ok, command_for(options.command), options.path, config}
  end
  defp validate_options(options, config) do
    {:error, options, config}
  end

  defp set_command_in_options(%Options{command: nil} = options, %Config{help: true}) do
    %Options{options | command: "help"}
  end
  defp set_command_in_options(%Options{command: nil} = options, %Config{version: true}) do
    %Options{options | command: "version"}
  end
  defp set_command_in_options(%Options{command: nil, path: path} = options, _config) do
    if Filename.contains_line_no?(path) do
      %Options{options | command: "explain"}
    else
      %Options{options | command: @default_command_name}
    end
  end
  defp set_command_in_options(options, _config), do: options

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
