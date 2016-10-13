defmodule Credo.CLI.Output.Summary do
  alias Credo.CLI.Filter
  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI
  alias Credo.Config
  alias Credo.Check.CodeHelper

  @category_wording [
    {:consistency, "consistency issue", "consistency issues"},
    {:warning, "warning", "warnings"},
    {:refactor, "refactoring opportunity", "refactoring opportunities"},
    {:readability, "code readability issue", "code readability issues"},
    {:design, "software design suggestion", "software design suggestions"},
  ]
  @cry_for_help "Please report incorrect results: https://github.com/rrrene/credo/issues"

  def print(_source_files, %Config{format: "flycheck"}, _time_load, _time_run) do
    nil
  end
  def print(_source_files, %Config{format: "oneline"}, _time_load, _time_run) do
    nil
  end
  def print(source_files, config, time_load, time_run) do
    issues =
      source_files
      |> Enum.map(&(&1.issues))
      |> List.flatten

    shown_issues =
      issues
      |> Filter.important(config)
      |> Filter.valid_issues(config)

    UI.puts
    UI.puts [:faint, @cry_for_help]
    UI.puts
    UI.puts [:faint, format_time_spent(time_load, time_run)]

    UI.puts summary_parts(source_files, shown_issues)

    # print_badge(source_files, issues)
    UI.puts

    shown_issues |> print_priority_hint(config)
  end

  def print_priority_hint([], %Config{min_priority: min_priority}) when min_priority >= 0 do
    "Use `--strict` to show all issues, `--help` for options."
    |> UI.puts(:faint)
  end
  def print_priority_hint([], _config), do: nil
  def print_priority_hint(_, %Config{min_priority: min_priority}) when min_priority >= 0 do
    "Showing priority issues: ↑ ↗ →  (use `--strict` to show all issues, `--help` for options)."
    |> UI.puts(:faint)
  end
  def print_priority_hint(_, _config), do: nil

  def print_badge([], _), do: nil
  def print_badge(source_files, issues) do
    scopes = scope_count(source_files)

    parts =
      @category_wording
      |> Enum.map(fn({category, _, _}) -> category_count(issues, category) end)

    parts = [scopes] ++ parts
    sum = Enum.sum(parts)

    width = 105

    bar =
      parts
      |> Enum.map(&(&1/sum))
      |> Enum.map(&Float.round(&1, 3))
      |> Enum.with_index
      |> Enum.map(fn({quota, index}) ->
          color =
            if index == 0 do
              :green
            else
              {category, _, _} = @category_wording |> Enum.at(index - 1)
              Output.check_color(category)
            end
          [color, String.duplicate("=", round(quota * width))]
        end)

    [bar]
    |> UI.puts
  end

  defp format_time_spent(time_load, time_run) do
    time_run  = time_run |> div(10_000)
    time_load = time_load |> div(10_000)

    formatted_total = format_in_seconds(time_run + time_load)
    total_in_seconds =
      case formatted_total do
        "1.0" -> "1 second"
        value -> "#{value} seconds"
      end
    "Analysis took #{total_in_seconds} (#{format_in_seconds time_load}s to load, #{format_in_seconds time_run}s running checks)"
  end

  defp format_in_seconds(t) do
    if t < 10 do
      "0.0#{t}"
    else
      t = div t, 10
      "#{div(t, 10)}.#{rem(t, 10)}"
    end
  end

  defp category_count(issues, category) do
    issues
    |> Enum.filter(&(&1.category == category))
    |> Enum.count
  end

  defp scope_count(source_files) do
    source_files
    |> Enum.flat_map(&CodeHelper.scope_list/1)
    |> Enum.uniq
    |> Enum.count
  end

  defp summary_parts(source_files, issues) do
    parts =
      @category_wording
      |> Enum.flat_map(&summary_part(&1, issues))

    parts =
      parts |> List.update_at(Enum.count(parts) - 1, fn(last_part) ->
        String.replace(last_part, ", ", "")
       end)

    parts = if Enum.empty?(parts), do: "no issues", else: parts

    [
      :green,
      "#{scope_count(source_files)} mods/funs, ",
      :reset,
      "found ",
      parts,
      "."
    ]
  end

  defp summary_part({category, singular, plural}, issues) do
    color = Output.check_color(category)

    case category_count(issues, category) do
      0 -> []
      1 -> [color, "1 #{singular}, "]
      x -> [color, "#{x} #{plural}, "]
    end
  end

end
