defmodule Credo.CLI do
  alias Credo.Config
  alias Credo.CLI.Filename

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

  def main(argv) do
    Credo.start nil, nil

    case run(argv) do
      :ok         -> System.halt(0)
      {:error, _} -> System.halt(1)
    end
  end

  def commands, do: Map.keys(@command_map)

  def command_for(nil), do: nil
  def command_for(command) do
    if Enum.member?(commands, command |> String.to_atom) do
      @command_map[command |> String.to_atom]
    else
      nil
    end
  end

  defp run(argv) do
    {command_mod, dir, config} = parse_options(argv)
    command_mod.run(dir, config)
  end

  defp parse_options(argv) do
    switches = [
      format: :string,
      checks: :string,
      ignore_checks: :string,
      min_priority: :integer
    ]
    aliases = [
      a: :all,
      c: :checks,
      C: :config_name,
      i: :ignore_checks,
      h: :help,
      v: :version,
    ]
    {switches, files, []} = OptionParser.parse(argv, switches: switches, aliases: aliases)

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
    config_name = Keyword.get(switches, :config_name)
    config = Config.read_or_default(dir, config_name)

    if Keyword.get(switches, :all) do
      config = %Config{config | all: true}
    end
    if Keyword.get(switches, :pedantic) do
      config = %Config{config | all: true, min_priority: -99}
    end
    if Keyword.get(switches, :help), do: config = %Config{config | help: true}
    if Keyword.get(switches, :one_line), do: config = %Config{config | one_line: true}
    if Keyword.get(switches, :verbose), do: config = %Config{config | verbose: true}
    if Keyword.get(switches, :version), do: config = %Config{config | version: true}
    if Keyword.get(switches, :crash_on_error), do: config = %Config{config | crash_on_error: true}

    min_priority = Keyword.get(switches, :min_priority)
    if min_priority do
      config =
        %Config{config | min_priority: min_priority}
    end

    # only include certain checks
    check_pattern = Keyword.get(switches, :checks)
    if check_pattern do
      config =
        %Config{config | match_checks: check_pattern |> String.split(",")}
    end

    # exclude/ignore certain checks
    ignore_pattern = Keyword.get(switches, :ignore_checks)
    if ignore_pattern do
      config =
        %Config{config | ignore_checks: ignore_pattern |> String.split(",")}
    end

    config
  end
end
