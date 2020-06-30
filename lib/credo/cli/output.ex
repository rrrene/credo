defmodule Credo.CLI.Output do
  @moduledoc """
  This module provides helper functions regarding command line output.
  """

  @category_tag_map %{"refactor" => "F"}

  alias Credo.CLI.Output.UI
  alias Credo.Execution

  def check_tag(category, in_parens \\ true)

  def check_tag(category, in_parens) when is_binary(category) do
    default_tag =
      category
      |> String.at(0)
      |> String.upcase()

    tag = Map.get(@category_tag_map, category, default_tag)

    if in_parens do
      "[#{tag}]"
    else
      tag
    end
  end

  def check_tag(category, in_parens) when is_atom(category) do
    category
    |> to_string
    |> check_tag(in_parens)
  end

  def check_tag(check_mod, in_parens) do
    check_mod.category
    |> to_string
    |> check_tag(in_parens)
  end

  def check_color(category) when is_binary(category) do
    case category do
      "consistency" -> :cyan
      "readability" -> :blue
      "design" -> :olive
      "refactor" -> :yellow
      "warning" -> :red
      _ -> :magenta
    end
  end

  def check_color(category) when is_atom(category) do
    category
    |> to_string
    |> check_color
  end

  def check_color(check_mod) do
    check_mod.category
    |> to_string
    |> check_color
  end

  # TODO: these need to correspond to the priorities in Credo.Priority
  def issue_color(issue) do
    priority = issue.priority

    cond do
      priority in 20..999 -> :red
      priority in 10..19 -> :red
      priority in 0..9 -> :yellow
      priority in -10..-1 -> :blue
      priority in -999..-11 -> :magenta
      true -> "?"
    end
  end

  # TODO: these need to correspond to the priorities in Credo.Priority
  def priority_arrow(priority) do
    cond do
      priority in 20..999 -> "\u2191"
      priority in 10..19 -> "\u2197"
      priority in 0..9 -> "\u2192"
      priority in -10..-1 -> "\u2198"
      priority in -999..-11 -> "\u2193"
      true -> "?"
    end
  end

  # TODO: these need to correspond to the priorities in Credo.Priority
  def priority_name(priority) do
    cond do
      priority in 20..999 -> "higher"
      priority in 10..19 -> "high"
      priority in 0..9 -> "normal"
      priority in -10..-1 -> "low"
      priority in -999..-11 -> "lower"
      true -> "?"
    end
  end

  @doc """
  Returns a suitable foreground color for a given `background_color`.

      iex> Credo.CLI.Output.foreground_color(:yellow)
      :black

      iex> Credo.CLI.Output.foreground_color(:blue)
      :white

  """
  def foreground_color(background_color)

  def foreground_color(:cyan), do: :black
  def foreground_color(:yellow), do: :black
  def foreground_color(_), do: :white

  def term_columns(default \\ 80) do
    case :io.columns() do
      {:ok, columns} ->
        columns

      _ ->
        default
    end
  end

  def complain_about_invalid_source_files([]), do: nil

  def complain_about_invalid_source_files(invalid_source_files) do
    invalid_source_filenames = Enum.map(invalid_source_files, & &1.filename)

    output = [
      :reset,
      :bright,
      :orange,
      "info: ",
      :red,
      "Some source files could not be parsed correctly and are excluded:\n"
    ]

    UI.warn(output)

    print_numbered_list(invalid_source_filenames)
  end

  def complain_about_timed_out_source_files([]), do: nil

  def complain_about_timed_out_source_files(large_source_files) do
    large_source_filenames = Enum.map(large_source_files, & &1.filename)

    output = [
      :reset,
      :bright,
      :orange,
      "info: ",
      :red,
      "Some source files were not parsed in the time allotted:\n"
    ]

    UI.warn(output)

    print_numbered_list(large_source_filenames)
  end

  def print_skipped_checks(%Execution{skipped_checks: []}), do: nil

  def print_skipped_checks(%Execution{skipped_checks: skipped_checks}) do
    msg = [
      :reset,
      :bright,
      :orange,
      "info: ",
      :reset,
      :faint,
      "some checks were skipped because they're not compatible with\n",
      :reset,
      :faint,
      "your version of Elixir (#{System.version()}).\n\n",
      "You can deactivate these checks by adding this to the `checks` list in your config:\n"
    ]

    UI.puts("")
    UI.puts(msg)

    skipped_checks
    |> Enum.map(&check_name/1)
    |> print_disabled_check_config
  end

  defp check_name({check, _check_info}), do: check_name({check})

  defp check_name({check}) do
    check
    |> to_string
    |> String.replace(~r/^Elixir\./, "")
  end

  defp print_numbered_list(list) do
    list
    |> Enum.with_index()
    |> Enum.flat_map(fn {string, index} ->
      [
        :reset,
        String.pad_leading("#{index + 1})", 5),
        :faint,
        " #{string}\n"
      ]
    end)
    |> UI.warn()
  end

  defp print_disabled_check_config(list) do
    list
    |> Enum.flat_map(fn string ->
      [
        :reset,
        String.pad_leading(" ", 4),
        :faint,
        "{#{string}, false},\n"
      ]
    end)
    |> UI.puts()
  end
end
