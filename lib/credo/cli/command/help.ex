defmodule Credo.CLI.Command.Help do
  @moduledoc false

  @shortdoc "Show this help message"

  @ljust 12
  @starting_order ~w(suggest explain)
  @ending_order ~w(help)

  use Credo.CLI.Command

  alias Credo.CLI.Output.UI
  alias Credo.CLI.Sorter
  alias Credo.Execution

  @doc false
  def call(exec, _opts) do
    print_banner()
    print_message(exec)

    exec
  end

  def print_banner do
    banner()
    |> String.split("")
    |> Enum.flat_map(fn x -> [color_for(x), x] end)
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

      name2 =
        name
        |> to_string
        |> String.pad_trailing(@ljust)

      case List.keyfind(module.__info__(:attributes), :shortdoc, 0) do
        {:shortdoc, [shortdesc]} ->
          UI.puts("  " <> name2 <> shortdesc)

        _ ->
          UI.puts("  " <> name2)
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

  def color_for("#"), do: [:faint]
  def color_for("\\"), do: :olive
  def color_for("/"), do: :olive
  def color_for("L"), do: :olive
  def color_for(_), do: [:reset, :white]

  def banner do
    output = """
    #   ____                    __
    #  /\\  _`\\                 /\\ \\
    #  \\ \\ \\/\\_\\  _ __    __   \\_\\ \\    ___
    #   \\ \\ \\/_/_/\\`'__\\/'__`\\ /'_` \\  / __`\\
    #    \\ \\ \\L\\ \\ \\ \\//\\  __//\\ \\L\\ \\/\\ \\L\\ \\
    #     \\ \\____/\\ \\_\\\\ \\____\\ \\___,_\\ \\____/
    #      \\/___/  \\/_/ \\/____/\\/__,_ /\\/___/
    #
    """

    String.trim(output)
  end
end
