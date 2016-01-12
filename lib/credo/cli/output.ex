defmodule Credo.CLI.Output do
  alias Credo.CLI.Output.UI

  @category_tag_map %{"refactor" => "F"}

  def check_tag(category, in_parens \\ true)

  def check_tag(category, in_parens) when is_binary(category) do
    default_tag = category |> String.at(0) |> String.upcase
    tag = Map.get(@category_tag_map, category, default_tag)
    if in_parens do
      "[#{tag}]"
    else
      tag
    end
  end
  def check_tag(category, in_parens) when is_atom(category) do
    category |> to_string |> check_tag(in_parens)
  end
  def check_tag(check_mod, in_parens) do
    check_mod.category |> to_string |> check_tag(in_parens)
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
    category |> to_string |> check_color
  end
  def check_color(check_mod) do
    check_mod.category |> to_string |> check_color
  end

  def issue_color(issue) do
    priority = issue.priority
    cond do
      priority in    20..999 -> :red
      priority in    10..19  -> :red
      priority in     0..9   -> :yellow
      priority in  -10..-1   -> :blue
      priority in -999..-11  -> :magenta
                      true   -> "?"
    end
  end

  def priority_arrow(priority) do
    cond do
      priority in    20..999 -> "\u2191"
      priority in    10..19  -> "\u2197"
      priority in     0..9   -> "\u2192"
      priority in   -2..-1   -> "\u2198"
      priority in -999..-1   -> "\u2193"
                      true   -> "?"
    end
  end

  def priority_name(priority) do
    cond do
      priority in    20..999 -> "high"
      priority in    10..19  -> "medium"
      priority in     0..9   -> "normal"
      priority in   -2..-1   -> "low"
      priority in -999..-1   -> "lower"
                      true   -> "?"
    end
  end

  def foreground_color(:cyan), do: :black
  def foreground_color(:yellow), do: :black
  def foreground_color(_), do: :white

  def term_columns(default \\ 80) do
    case :io.columns do
      {:ok, columns} -> columns
      _ -> default
    end
  end

  def complain_about_invalid_source_files([]), do: nil
  def complain_about_invalid_source_files(invalid_source_files) do
    invalid_source_filenames = Enum.map(invalid_source_files, &(&1.filename))
    [
      :red, "Some source files could not be parsed correctly and are excluded:\n",
    ]
    |> UI.puts

    invalid_source_filenames
    |> Enum.with_index
    |> Enum.flat_map(fn({filename, index}) ->
        [:reset, "#{index+1})" |> String.rjust(5), :faint, " #{filename}\n"]
      end)
    |> UI.puts
  end
end
