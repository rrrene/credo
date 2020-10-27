defmodule Credo.CLI.Command.Diff.DiffSummary do
  @moduledoc false

  # This module is responsible for printing the summary at the end of the analysis.

  @category_wording [
    {:consistency, "consistency issue", "consistency issues"},
    {:warning, "warning", "warnings"},
    {:refactor, "refactoring opportunity", "refactoring opportunities"},
    {:readability, "code readability issue", "code readability issues"},
    {:design, "software design suggestion", "software design suggestions"}
  ]
  @cry_for_help "Please report incorrect results: https://github.com/rrrene/credo/issues"

  alias Credo.CLI.Output
  alias Credo.CLI.Output.UI
  alias Credo.Execution

  def print(
        _source_files,
        %Execution{format: "flycheck"},
        _time_load,
        _time_run
      ) do
    nil
  end

  def print(_source_files, %Execution{format: "oneline"}, _time_load, _time_run) do
    nil
  end

  def print(source_files, exec, time_load, time_run) do
    issues = Execution.get_issues(exec)
    source_file_count = exec |> Execution.get_source_files() |> Enum.count()
    checks_count = count_checks(exec)

    git_ref = Execution.get_assign(exec, "credo.diff.previous_git_ref")

    UI.puts()
    UI.puts([:faint, @cry_for_help])
    UI.puts()

    UI.puts(format_time_spent(checks_count, source_file_count, time_load, time_run))
    UI.puts()

    new_issues = Enum.filter(issues, &(&1.diff_marker == :new))
    fixed_issues = Enum.filter(issues, &(&1.diff_marker == :fixed))
    old_issues = Enum.filter(issues, &(&1.diff_marker == :old))

    UI.puts([
      "Changes between ",
      :faint,
      :cyan,
      git_ref,
      :reset,
      " and working dir:"
    ])

    UI.puts()
    UI.puts(summary_parts_new(source_files, new_issues))
    UI.puts(summary_parts_fixed(source_files, fixed_issues))
    UI.puts(summary_parts_old(source_files, old_issues))
    UI.puts()

    print_priority_hint(exec)
  end

  defp count_checks(exec) do
    {result, _only_matching, _ignore_matching} = Execution.checks(exec)

    Enum.count(result)
  end

  defp print_priority_hint(%Execution{min_priority: min_priority})
       when min_priority >= 0 do
    UI.puts([
      :faint,
      "Showing priority issues: ↑ ↗ →  (use `mix credo explain` to explain issues, `mix credo diff --help` for options)."
    ])
  end

  defp print_priority_hint(_) do
    UI.puts([
      :faint,
      "Use `mix credo explain` to explain issues, `mix credo diff --help` for options."
    ])
  end

  defp format_time_spent(check_count, source_file_count, time_load, time_run) do
    time_run = time_run |> div(10_000)
    time_load = time_load |> div(10_000)

    formatted_total = format_in_seconds(time_run + time_load)

    time_to_load = format_in_seconds(time_load)
    time_to_run = format_in_seconds(time_run)

    total_in_seconds =
      case formatted_total do
        "1.0" -> "1 second"
        value -> "#{value} seconds"
      end

    checks =
      if check_count == 1 do
        "1 check"
      else
        "#{check_count} checks"
      end

    source_files =
      if source_file_count == 1 do
        "1 file"
      else
        "#{source_file_count} files"
      end

    [
      :faint,
      "Analysis took #{total_in_seconds} ",
      "(#{time_to_load}s to load, #{time_to_run}s running #{checks} on #{source_files})"
    ]
  end

  defp format_in_seconds(t) do
    if t < 10 do
      "0.0#{t}"
    else
      t = div(t, 10)
      "#{div(t, 10)}.#{rem(t, 10)}"
    end
  end

  defp category_count(issues, category) do
    issues
    |> Enum.filter(&(&1.category == category))
    |> Enum.count()
  end

  defp summary_parts_new(_source_files, issues) do
    parts =
      @category_wording
      |> Enum.flat_map(&summary_part(&1, issues, "new "))

    parts =
      parts
      |> List.update_at(Enum.count(parts) - 1, fn last_part ->
        String.replace(last_part, ", ", "")
      end)

    parts =
      if Enum.empty?(parts) do
        "no issues"
      else
        parts
      end

    [
      :green,
      :bright,
      "+ ",
      :reset,
      :green,
      " added ",
      :reset,
      parts,
      ","
    ]
  end

  defp summary_parts_fixed(_source_files, issues) do
    parts =
      @category_wording
      |> Enum.flat_map(&summary_part(&1, issues))

    parts =
      parts
      |> List.update_at(Enum.count(parts) - 1, fn last_part ->
        String.replace(last_part, ", ", "")
      end)

    parts =
      if Enum.empty?(parts) do
        "no issues"
      else
        parts
      end

    [
      :faint,
      "✔ ",
      :reset,
      " fixed ",
      :faint,
      parts,
      ", and"
    ]
  end

  defp summary_parts_old(_source_files, issues) do
    parts =
      @category_wording
      |> Enum.flat_map(&summary_part(&1, issues))
      |> Enum.reject(&is_atom(&1))

    parts =
      parts
      |> List.update_at(Enum.count(parts) - 1, fn last_part ->
        String.replace(last_part, ", ", "")
      end)

    parts =
      if Enum.empty?(parts) do
        "no issues"
      else
        parts
      end

    [
      :faint,
      "~ ",
      " kept ",
      parts,
      "."
    ]
  end

  defp summary_part({category, singular, plural}, issues, qualifier \\ "") do
    color = Output.check_color(category)

    case category_count(issues, category) do
      0 -> []
      1 -> [color, "1 #{qualifier}#{singular}, "]
      x -> [color, "#{x} #{qualifier}#{plural}, "]
    end
  end
end
