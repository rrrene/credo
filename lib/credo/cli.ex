defmodule Credo.CLI do
  @moduledoc """
  Credo.CLI is the entrypoint for both the Mix task and the escript.

  It takes the parameters passed from the command line and translates them into
  a Command module (see the `Credo.CLI.Command` namespace), the work directory
  where the Command should run and a `Credo.Config` object.
  """

  use Bitwise

  alias Credo.Config
  alias Credo.Sources
  alias Credo.CLI.Filename
  alias Credo.CLI.Switches

  @default_dir "."
  @default_command_name "suggest"
  @command_map %{
    "categories" => Credo.CLI.Command.Categories,
    "explain" => Credo.CLI.Command.Explain,
    "gen.check" => Credo.CLI.Command.GenCheck,
    "gen.config" => Credo.CLI.Command.GenConfig,
    "help" => Credo.CLI.Command.Help,
    "list" => Credo.CLI.Command.List,
    "suggest" => Credo.CLI.Command.Suggest,
    "version" => Credo.CLI.Command.Version,
  }
  @switches [
    all: :boolean,
    all_priorities: :boolean,
    checks: :string,
    crash_on_error: :boolean,
    format: :string,
    help: :boolean,
    ignore_checks: :string,
    min_priority: :integer,
    read_from_stdin: :boolean,
    strict: :boolean,
    verbose: :boolean,
    version: :boolean
  ]
  @aliases [
    a: :all,
    A: :all_priorities,
    c: :checks,
    C: :config_name,
    h: :help,
    i: :ignore_checks,
    v: :version
  ]

  @doc false
  def main(argv) do
    Credo.start nil, nil

    argv
    |> run()
    |> to_exit_status()
    |> halt_if_failed()
  end

  @doc "Returns a List with the names of all commands."
  def commands, do: Map.keys(@command_map)

  @doc """
  Returns the module of a given `command`.

      iex> command_for(:help)
      Credo.CLI.Command.Help
  """
  def command_for(nil), do: nil
  def command_for(command) when is_atom(command) do
    command_modules = Map.values(@command_map)
    if Enum.member?(command_modules, command) do
      command
    else
      nil
    end
  end
  def command_for(command) when is_binary(command) do
    if Enum.member?(commands(), command) do
      @command_map[command]
    else
      nil
    end
  end

  defp run(argv) do
    {command_mod, dir, config} = parse_options(argv)

    if config.check_for_updates, do: Credo.CheckForUpdates.run()

    config |> require_requires()

    command_mod.run(dir, config)
  end

  # Requires the additional files specified in the config.
  defp require_requires(%Config{requires: requires}) do
    requires
    |> Sources.find
    |> Enum.each(&Code.require_file/1)
  end

  defp parse_options(argv) do
    {switches_kw, args, []} =
      OptionParser.parse(argv, switches: @switches, aliases: @aliases)

    {command_name, given_directory, args} =
      case args |> List.first |> command_for() do
        nil ->
          {nil, Enum.at(args, 0), args}
        command_name ->
          {command_name, Enum.at(args, 1), args |> Enum.slice(1..-1)}
      end

    dir = given_directory || @default_dir
    switches = switches_kw |> Enum.into(%{})
    config = dir |> to_config(switches)

    command_name_dir_config(command_name, args, config)
  end

  defp command_name_dir_config(nil, args, %Config{help: true} = config) do
    command_name_dir_config("help", args, config)
  end
  defp command_name_dir_config(nil, args, %Config{version: true} = config) do
    command_name_dir_config("version", args, config)
  end
  defp command_name_dir_config(nil, [], config) do
    command_name_dir_config(@default_command_name, [], config)
  end
  defp command_name_dir_config(nil, args, config) do
    if args |> List.first |> Filename.contains_line_no?() do
      command_name_dir_config("explain", args, config)
    else
      command_name_dir_config(@default_command_name, args, config)
    end
  end
  defp command_name_dir_config(command_name, args, config) do
    {command_for(command_name), args, config}
  end

  defp to_config(dir, switches) do
    dir
    |> Filename.remove_line_no_and_column
    |> Config.read_or_default(switches[:config_name])
    |> Switches.parse_to_config(switches)
  end

  # Converts the return value of a Command.run() call into an exit_status
  defp to_exit_status(:ok), do: 0
  defp to_exit_status({:error, issues}) do
    issues
    |> Enum.map(&(&1.exit_status))
    |> Enum.reduce(0, &(&1 ||| &2))
  end

  defp halt_if_failed(0), do: nil
  defp halt_if_failed(x), do: x |> System.halt
end
