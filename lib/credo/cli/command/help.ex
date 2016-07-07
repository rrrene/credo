defmodule Credo.CLI.Command.Help do
  use Credo.CLI.Command


  @shortdoc "Show this help message"
  @ljust 12
  @starting_order [:suggest, :explain]
  @ending_order [:help]

  @cry_for_help "Please report incorrect results: https://github.com/rrrene/credo/issues"

  alias Credo.CLI
  alias Credo.CLI.Output.UI
  alias Credo.CLI.Sorter

  def run(_, _) do
    print_banner()
    print_message()
  end

  def print_banner do
    banner()
    |> String.split("")
    |> Enum.flat_map(fn(x) -> [color_for(x), x] end)
    |> UI.puts

    #"# #{@cry_for_help}"
    #|> UI.puts(:faint)

    UI.puts
    :ok
  end

  def print_message do
    UI.puts "Credo Version #{Credo.version}"
    UI.puts ["Usage: ", :olive, "$ mix credo <command> [options]"]
    UI.puts "\nCommands:\n"

    CLI.commands
    |> Sorter.ensure(@starting_order, @ending_order)
    |> Enum.each(fn(name) ->
      module = name |> CLI.command_for
      name2 = name |> to_string |> String.ljust(@ljust)
      case List.keyfind(module.__info__(:attributes), :shortdoc, 0) do
        {:shortdoc, [shortdesc]} ->
          UI.puts "  " <> name2 <> shortdesc
        _ ->
          nil # skip commands without @shortdesc
      end
    end)

    UI.puts "\nUse `--help` on any command to get further information."

    [
      "For example, `", :olive, "mix credo suggest --help",
        :reset, "` for help on the default command."
    ]
    |> UI.puts
  end

  def color_for("#"), do: [:faint]
  def color_for("\\"), do: :olive
  def color_for("/"), do: :olive
  def color_for("L"), do: :olive
  def color_for(_), do: [:reset, :white]

  def banner do
"""
#   ____                    __
#  /\\  _`\\                 /\\ \\
#  \\ \\ \\/\\_\\  _ __    __   \\_\\ \\    ___
#   \\ \\ \\/_/_/\\`'__\\/'__`\\ /'_` \\  / __`\\
#    \\ \\ \\L\\ \\ \\ \\//\\  __//\\ \\L\\ \\/\\ \\L\\ \\
#     \\ \\____/\\ \\_\\\\ \\____\\ \\___,_\\ \\____/
#      \\/___/  \\/_/ \\/____/\\/__,_ /\\/___/
#
""" |> String.strip
  end

end
