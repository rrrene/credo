defmodule Credo.CLI.Command.Help do
  alias Credo.CLI.Output.UI

  @cry_for_help "Please report incorrect results: https://github.com/rrrene/credo/issues"

  def run(_, _) do
    print_banner
    print_message
  end

  def print_banner do
    banner
    |> String.split("")
    |> Enum.flat_map(fn(x) -> [color_for(x), x] end)
    |> UI.puts

    #"# #{@cry_for_help}"
    #|> UI.puts(:faint)

    UI.puts
  end

  def print_message do
    """
    Credo Version #{Credo.version}
    """
    |> UI.puts
    ["Usage: ", :olive, "$ mix credo <command> [options]"]
    |> UI.puts
    """

    Commands:
      suggest   Suggest code objects to look at next (default)
      explain   Show code object and explain why it is/might be an issue
      list      List all code objects with their results
      help      Show this help message

    Use `--help` on any command to get further information.
    """
    |> UI.puts
    ["For example, `", :olive, "mix credo suggest --help",
      :reset, "` for help on the default command."]
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
