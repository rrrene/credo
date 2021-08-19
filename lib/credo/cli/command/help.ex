defmodule Credo.CLI.Command.Help do
  @moduledoc false

  @ljust 12
  @starting_order ~w(suggest explain)
  @ending_order ~w(help)

  alias Credo.CLI.Output.UI
  alias Credo.CLI.Sorter
  alias Credo.CLI.Switch
  alias Credo.Execution

  use Credo.CLI.Command,
    short_description: "Show this help message",
    cli_switches: [
      Switch.string("format"),
      Switch.boolean("help", alias: :h)
    ]

  @doc false
  def call(exec, _opts) do
    print_banner()
    print_message(exec)

    exec
  end

  def print_banner do
    banner()
    |> String.split("")
    |> Enum.flat_map(fn char -> [color_for(char), char_for(char)] end)
    |> UI.puts()

    UI.puts()
  end

  def print_message(exec) do
    UI.puts("Credo Version #{Credo.version()}")
    UI.puts(["Usage: ", :olive, "$ mix credo <command> [options]"])
    UI.puts("\nCommands:\n")

    exec
    |> Execution.get_valid_command_names()
    |> Sorter.ensure(@starting_order, @ending_order)
    |> Enum.each(fn name ->
      module = Execution.get_command(exec, name)

      padded_name =
        name
        |> to_string
        |> String.pad_trailing(@ljust)

      case module.short_description do
        nil ->
          UI.puts("  #{padded_name}")

        short_description ->
          UI.puts("  #{padded_name}#{short_description}")
      end
    end)

    UI.puts("\nUse `--help` on any command to get further information.")

    example = [
      "For example, `",
      :olive,
      "mix credo suggest --help",
      :reset,
      "` for help on the default command."
    ]

    UI.puts(example)
  end

  def color_for("#"), do: [:reset, :darkgreen]
  def color_for(";"), do: [:reset, :faint, :green]
  def color_for("~"), do: [:reset, :bright, :green]
  def color_for(":"), do: [:reset, :faint, :yellow]
  def color_for("="), do: [:reset, :bright, :yellow]
  def color_for("-"), do: [:reset, :faint, :red]
  def color_for("["), do: [:reset, :bright, :red]
  def color_for("M"), do: [:reset, :blue]
  def color_for(","), do: [:reset, :color235]
  def color_for(_), do: [:reset, :white]

  # ~w(▁ ▂ ▃ ▄ ▅ ▆ ▇ █)

  def char_for(" "), do: " "
  def char_for("\n"), do: "\n"
  def char_for("#"), do: "▇"
  def char_for(";"), do: "▇"
  def char_for("~"), do: "▇"
  def char_for(":"), do: "▇"
  def char_for("="), do: "▇"
  def char_for("-"), do: "▇"
  def char_for("["), do: "▇"
  def char_for("M"), do: "▇"
  def char_for(","), do: "▅"
  def char_for(v), do: v

  def banner do
    """

                        #######################     #####    ###
                        #######################,,,,,#####,,, ###
                           ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
                          ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
                   ~~~~~~~~~~~~~~~~~,,,~~~~~~~~,,,~~~,,,,,,,,,,,
             ;;;;;;~~~~~~~~~~~~~~~~~,,,~~~~~~~~,,,~~~,,,,,,,,,,,
             ;;;;;;;;;;;;;,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
                          ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
      ::::::::::::::::::::,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
      :::::===================,,,==========,,,==,,,,,,,,,,,,,,,,
           ===================,,,==========,,,==,,,,,,,,,,,,,,,,
                          ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
          ----------------,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
          -------[[[[[[[[[[[[[[[[[[[[[[[,,,[[,,,[[[[[[,,,,,,,,,,
                 [[[[[[[[[[[[[[[[[[[[[[[,,,[[,,,[[[[[[,,,,,,,,,,
                          ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
                           ,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,,
                        MMMMMMMMMMMMMMMMMMMMMMM,,,,MMMMM,,,, MMM
                        MMMMMMMMMMMMMMMMMMMMMMM    MMMMM     MMM
    """
  end
end
