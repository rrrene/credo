defmodule Credo.CLI.Output.Categories do
  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI

  @order [:design, :readability, :refactor, :warning, :consistency]
  @category_colors [
    design: :olive,
    readability: :blue,
    refactor: :yellow,
    warning: :red,
    consistency: :cyan,
  ]
  @category_titles [
    design: "Software Design",
    readability: "Code Readability",
    refactor: "Refactoring opportunities",
    warning: "Warnings - please take a look",
    consistency: "Consistency",
  ]
  @category_texts [
    design: """
    These checks take a look at your code and ensure a consistent coding style.
    Using tabs or spaces? Both is fine, just don't mix them or Credo will tell
    you.
    """,
    readability: """
    Readability checks do not concern themselves with the technical correctness
    of your code, but how easy it is to digest.
    """,
    refactor: """
    The Refactor checks show you opportunities to avoid future problems and
    technical debt.
    """,
    warning: """
    While refactor checks show you possible problems, these checks try to
    highlight possibilities, like - potentially intended - duplicated code or
    TODO and FIXME comments.
    """,
    consistency: """
    These checks warn you about things that are potentially dangerous, like a
    missed call to `IEx.pry` you put in during a debugging session or a call
    to String.downcase without using the result.
    """,
  ]

  def print do
    Enum.each(@order, &print_category/1)
  end

  defp print_category(category) do
    term_width = Output.term_columns
    color = @category_colors[category]
    title = @category_titles[category]
    output = [
      :bright, String.to_atom("#{color}_background"), color, " ",
      Output.foreground_color(color), :normal,
      String.ljust(" #{title}", term_width - 1),
    ]

    UI.puts
    UI.puts(output)

    color
    |> UI.edge
    |> UI.puts

    @category_texts[category]
    |> String.split("\n")
    |> Enum.each(&print_line(&1, color))
  end

  defp print_line(line, color) do
    output = [UI.edge(color), " ", :reset, line]
    UI.puts(output)
  end

end
