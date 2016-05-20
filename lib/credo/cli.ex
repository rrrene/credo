defmodule Credo.CLI do
  @moduledoc """
  Credo.CLI is the entrypoint for both the Mix task and the escript.

  It takes the parameters passed from the command line and translates them into
  a Command module (see the `Credo.CLI.Command` namespace), the work directory
  where the Command should run and a `Credo.Config` object.
  """

  use Bitwise

  alias Credo.Config
  alias Credo.CLI.Filename
  alias Credo.CLI.Output.UI

  @default_dir "."
  @default_command_name "suggest"
  @command_map %{
    help: Credo.CLI.Command.Help,
    list: Credo.CLI.Command.List,
    suggest: Credo.CLI.Command.Suggest,
    explain: Credo.CLI.Command.Explain,
    categories: Credo.CLI.Command.Categories,
    version: Credo.CLI.Command.Version
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
  def command_for(command) when is_binary(command) do
    command_for(command |> String.to_atom)
  end
  def command_for(command) when is_atom(command) do
    if Enum.member?(commands, command) do
      @command_map[command]
    else
      nil
    end
  end

  defp run(argv) do
    {command_mod, dir, config} = parse_options(argv)

    command_mod.run(dir, config)
  end

  defp parse_options(argv) do
    {switches, files, []} =
      OptionParser.parse(argv, switches: @switches, aliases: @aliases)

    {command_name, files} =
      if files |> List.first |> command_for do
        [command_name | files] = files
        {command_name, files}
      else
        {nil, files}
      end

    dir = (files |> List.first) || @default_dir
    config = dir |> to_config(switches)

    command_name_dir_config(command_name, dir, config)
  end

  defp command_name_dir_config(nil, dir, %Config{help: true} = config) do
    command_name_dir_config("help", dir, config)
  end
  defp command_name_dir_config(nil, dir, %Config{version: true} = config) do
    command_name_dir_config("version", dir, config)
  end
  defp command_name_dir_config(nil, dir, config) do
    if Filename.contains_line_no?(dir) do
      command_name_dir_config("explain", dir, config)
    else
      command_name_dir_config(@default_command_name, dir, config)
    end
  end
  defp command_name_dir_config(command_name, dir, config) do
    {command_for(command_name), dir, config}
  end

  defp to_config(dir, switches) do
    dir = Filename.remove_line_no_and_column(dir)
    config = Config.read_or_default(dir, switches[:config_name])
    Enum.reduce(switches, config, &apply_config/2)
  end

  @simple_configs ~w(all help verbose version crash_on_error read_from_stdin
    min_priority format)

  defp apply_config(config, {key, value}) when key in @simple_configs,
    do: Map.put(config, key, value)
  defp apply_config(config, {key, true}) when key in [:all_priorities, :strict],
    do: %Config{config | all: true, min_priority: -99}
  defp apply_config(config, {checks, patterns}) when checks in [:checks, :only],
    do: %Config{config | all: true, match_checks: String.split(patterns, ",")}
  defp apply_config(config, {ignore, patterns}) when ignore in [:ignore_checks, :ignore],
    do: %Config{config | ignore_checks: String.split(patterns, ",")}
  # DEPRECATED command line switches:
  defp apply_config(config, {:one_line, true}) do
    UI.puts [:yellow, "[DEPRECATED] ", :faint, "--one-line is deprecated in favor of --format=oneline"]
    %Config{config | format: "oneline"}
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
