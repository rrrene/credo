defmodule Credo.CLI do
  @moduledoc """
  Credo.CLI is the entrypoint for both the Mix task and the escript.

  It takes the parameters passed from the command line and translates them into
  a Command module (see the `Credo.CLI.Command` namespace), the work directory
  where the Command should run and a `Credo.Config` object.
  """

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
    strict: :boolean,
    verbose: :boolean,
    version: :boolean,
    stdin: :boolean
  ]
  @aliases [
    a: :all,
    A: :all_priorities,
    c: :checks,
    C: :config_name,
    h: :help,
    i: :ignore_checks,
    v: :version,
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

    command_name =
      if files |> List.first |> command_for do
        command_name = files |> List.first
        files = files |> List.delete_at(0)
        command_name
      else
        nil
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
    dir = dir |> Filename.remove_line_no_and_column
    config_name = switch(switches, :config_name)
    config = Config.read_or_default(dir, config_name)

    if switch(switches, :all) do
      config = %Config{config | all: true}
    end
    if switch(switches, :all_priorities, :strict) do
      config = %Config{config | all: true, min_priority: -99}
    end
    if switch(switches, :help), do: config = %Config{config | help: true}
    if switch(switches, :verbose), do: config = %Config{config | verbose: true}
    if switch(switches, :version), do: config = %Config{config | version: true}
    if switch(switches, :crash_on_error), do: config = %Config{config | crash_on_error: true}
    if switch(switches, :stdin), do: config = %Config{config | stdin: true, files: %{included: [dir], excluded: []}}

    min_priority = switch(switches, :min_priority)
    if min_priority do
      config =
        %Config{config | min_priority: min_priority}
    end

    format = switch(switches, :format)
    if format do
      config =
        %Config{config | format: format}
    end

    # only include certain checks
    check_pattern = switch(switches, :checks, :only)
    if check_pattern do
      config =
        %Config{config | all: true, match_checks: check_pattern |> String.split(",")}
    end

    # exclude/ignore certain checks
    ignore_pattern = switch(switches, :ignore_checks, :ignore)
    if ignore_pattern do
      config =
        %Config{config | ignore_checks: ignore_pattern |> String.split(",")}
    end

    # DEPRECATED command line switches:

    if switch(switches, :one_line) do
      UI.puts [:yellow, "[DEPRECATED] ", :faint, "--one-line is deprecated in favor of --format=oneline"]
      config = %Config{config | format: "oneline"}
    end

    config
  end

  def switch(switches, key), do: Keyword.get(switches, key)
  def switch(switches, key, alias_key) do
    Keyword.get(switches, key) || Keyword.get(switches, alias_key)
  end

  # Converts the return value of a Command.run() call into an exit_status
  defp to_exit_status(:ok), do: 0
  defp to_exit_status({:error, issues}) do
    issues
    |> Enum.map(&(&1.exit_status))
    |> Enum.uniq
    |> Enum.reduce(0, &(&1+&2))
  end

  defp halt_if_failed(0), do: nil
  defp halt_if_failed(x), do: x |> System.halt
end
