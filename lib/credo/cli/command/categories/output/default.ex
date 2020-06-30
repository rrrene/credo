defmodule Credo.CLI.Command.Categories.Output.Default do
  @moduledoc false

  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI

  def print(_exec, categories) do
    Enum.each(categories, &print_category/1)
  end

  defp print_category(%{color: color, title: title, description: text}) do
    term_width = Output.term_columns()

    UI.puts()

    [
      :bright,
      "#{color}_background" |> String.to_atom(),
      color,
      " ",
      Output.foreground_color(color),
      :normal,
      " #{title}" |> String.pad_trailing(term_width - 1)
    ]
    |> UI.puts()

    color
    |> UI.edge()
    |> UI.puts()

    text
    |> String.split("\n")
    |> Enum.each(&print_line(&1, color))
  end

  defp print_line(line, color) do
    [UI.edge(color), " ", :reset, line]
    |> UI.puts()
  end
end
