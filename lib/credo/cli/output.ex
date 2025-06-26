defmodule Credo.CLI.Output do
  @moduledoc """
  This module provides helper functions regarding command line output.
  """

  @category_tag_map %{"refactor" => "F"}

  alias Credo.CLI.Output.UI
  alias Credo.Execution
  alias Credo.Priority

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

  def check_color(%{} = issue_or_map) do
    issue_or_map.category
    |> to_string
    |> check_color
  end

  @doc """
  Returns a suitable color for a given priority.

      iex> Credo.CLI.Output.issue_color(%Credo.Issue{priority: :higher})
      :red

      iex> Credo.CLI.Output.issue_color(%Credo.Issue{priority: 20})
      :red

  """
  def issue_color(issue_or_priority) do
    case Priority.to_atom(issue_or_priority) do
      :higher -> :red
      :high -> :red
      :normal -> :yellow
      :low -> :blue
      :ignore -> :magenta
      _ -> "?"
    end
  end

  @doc """
  Returns a suitable arrow for a given priority.

      iex> Credo.CLI.Output.priority_arrow(:high)
      "↗"

      iex> Credo.CLI.Output.priority_arrow(10)
      "↗"

      iex> Credo.CLI.Output.priority_arrow(%Credo.Issue{priority: 10})
      "↗"
  """
  def priority_arrow(issue_or_priority) do
    case Priority.to_atom(issue_or_priority) do
      :higher -> "\u2191"
      :high -> "\u2197"
      :normal -> "\u2192"
      :low -> "\u2198"
      :ignore -> "\u2193"
      _ -> "?"
    end
  end

  @doc """
  Returns a suitable name for a given priority.

      iex> Credo.CLI.Output.priority_name(:normal)
      "normal"

      iex> Credo.CLI.Output.priority_name(1)
      "normal"

      iex> Credo.CLI.Output.priority_name(%Credo.Issue{priority: 1})
      "normal"

  """
  def priority_name(issue_or_priority) do
    case Priority.to_atom(issue_or_priority) do
      :higher -> "higher"
      :high -> "high"
      :normal -> "normal"
      :low -> "low"
      :ignore -> "ignore"
      _ -> "?"
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
      "You can deactivate these checks by adding them to the `:checks`/`:disabled` list in your config:\n"
    ]

    UI.puts("")
    UI.puts(msg)

    UI.puts([
      :faint,
      """
        checks: %{
          disabled: [
      """
      |> String.trim_trailing()
    ])

    skipped_checks
    |> Enum.flat_map(fn {check, params} ->
      [
        :reset,
        :cyan,
        "      {#{Credo.Code.Module.name(check)}, #{inspect(params)}},\t# requires Elixir #{check.elixir_version()}\n"
      ]
    end)
    |> UI.puts()

    UI.puts([
      :faint,
      """
            # ...
          ]
        }
      """
    ])
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
end
