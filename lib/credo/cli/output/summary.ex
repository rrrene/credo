defmodule Credo.CLI.Output.Summary do
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
  alias Credo.CLI.Output.FirstRunHint
  alias Credo.CLI.Output.UI
  alias Credo.Execution
  alias Credo.SourceFile

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

    print_cry_for_help(exec)

    UI.puts([:faint, format_time_spent(checks_count, source_file_count, time_load, time_run)])

    UI.puts(summary_parts(source_files, issues))

    print_issue_type_summary(issues, exec)
    print_issue_name_summary(issues, exec)
    print_top_files_summary(issues, exec)

    print_priority_hint(exec)
    print_first_run_hint(exec)
  end

  defp print_first_run_hint(%Execution{cli_options: %{switches: %{first_run: true}}} = exec) do
    FirstRunHint.call(exec)
  end

  defp print_first_run_hint(exec), do: exec

  defp print_cry_for_help(%Execution{format: "short"}) do
    nil
  end

  defp print_cry_for_help(_exec) do
    UI.puts()
    UI.puts([:faint, @cry_for_help])
    UI.puts()
  end

  defp count_checks(exec) do
    {result, _only_matching, _ignore_matching} = Execution.checks(exec)

    Enum.count(result)
  end

  defp print_priority_hint(%Execution{format: "short"}) do
    nil
  end

  defp print_priority_hint(%Execution{min_priority: min_priority})
       when min_priority >= 0 do
    UI.puts()

    UI.puts([
      :faint,
      "Showing priority issues: ↑ ↗ →  (use `mix credo explain` to explain issues, `mix credo --help` for options)."
    ])
  end

  defp print_priority_hint(_) do
    UI.puts()

    UI.puts([
      :faint,
      "Use `mix credo explain` to explain issues, `mix credo --help` for options."
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

    breakdown = "#{time_to_load}s to load, #{time_to_run}s running #{checks} on #{source_files}"

    "Analysis took #{total_in_seconds} (#{breakdown})"
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
    |> Enum.count(&(&1.category == category))
  end

  defp summary_parts(source_files, issues) do
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

  defp scope_count(%SourceFile{} = source_file) do
    Credo.Code.prewalk(source_file, &scope_count_traverse/2, 0)
  end

  defp scope_count(source_files) when is_list(source_files) do
    source_files
    |> Task.async_stream(&scope_count/1, ordered: false)
    |> Enum.reduce(0, fn {:ok, n}, sum -> n + sum end)
  end

  @def_ops [:defmodule, :def, :defp, :defmacro]
  for op <- @def_ops do
    defp scope_count_traverse({unquote(op), _, _} = ast, count) do
      {ast, count + 1}
    end
  end

  defp scope_count_traverse(ast, count) do
    {ast, count}
  end

  defp print_issue_type_summary([], _exec), do: nil

  defp print_issue_type_summary(_issues, %Execution{format: "short"}), do: nil

  defp print_issue_type_summary(issues, _exec) do
    UI.puts()
    UI.puts([:bright, "Issue Type Summary:"])

    issue_type_counts =
      issues
      |> Enum.group_by(& &1.category)
      |> Enum.map(fn {category, category_issues} ->
        {category, Enum.count(category_issues)}
      end)
      |> Enum.sort_by(fn {_category, count} -> count end, :desc)

    total_issues = Enum.count(issues)

    issue_type_counts
    |> Enum.reduce(0, fn {category, count}, cumulative_count ->
      color = Output.check_color(category)
      percentage = if total_issues > 0, do: Float.round(count / total_issues * 100, 1), else: 0.0
      new_cumulative = cumulative_count + count
      cumulative_percentage = if total_issues > 0, do: Float.round(new_cumulative / total_issues * 100, 1), else: 0.0

      UI.puts([
        "  ",
        color,
        String.pad_trailing("#{category}", 15),
        :reset,
        ": ",
        :bright,
        String.pad_leading("#{count}", 5),
        :reset,
        " (",
        :faint,
        "#{percentage}%",
        :reset,
        ", cumulative: ",
        :faint,
        "#{cumulative_percentage}%",
        :reset,
        ")"
      ])

      new_cumulative
    end)
  end

  defp print_issue_name_summary([], _exec), do: nil

  defp print_issue_name_summary(_issues, %Execution{format: "short"}), do: nil

  defp print_issue_name_summary(issues, _exec) do
    UI.puts()
    UI.puts([:bright, "Issue Name Summary:"])

    issue_name_counts =
      issues
      |> Enum.group_by(& &1.check)
      |> Enum.map(fn {check, check_issues} ->
        {check, Enum.count(check_issues)}
      end)
      |> Enum.sort_by(fn {_check, count} -> count end, :desc)

    total_issues = Enum.count(issues)

    issue_name_counts
    |> Enum.reduce(0, fn {check, count}, cumulative_count ->
      check_name = check |> to_string() |> String.replace("Elixir.", "")
      category = check.category()
      color = Output.check_color(category)
      percentage = if total_issues > 0, do: Float.round(count / total_issues * 100, 1), else: 0.0
      new_cumulative = cumulative_count + count
      cumulative_percentage = if total_issues > 0, do: Float.round(new_cumulative / total_issues * 100, 1), else: 0.0

      UI.puts([
        "  ",
        color,
        String.pad_trailing(check_name, 60),
        :reset,
        " ",
        :bright,
        String.pad_leading("#{count}", 5),
        :reset,
        " (",
        :faint,
        "#{percentage}%",
        :reset,
        ", cumulative: ",
        :faint,
        "#{cumulative_percentage}%",
        :reset,
        ")"
      ])

      new_cumulative
    end)
  end

  defp print_top_files_summary([], _exec), do: nil

  defp print_top_files_summary(_issues, %Execution{format: "short"}), do: nil

  defp print_top_files_summary(issues, exec) do
    top_files_count = get_top_files_count(exec)

    UI.puts()
    UI.puts([:bright, "Top #{top_files_count} Files with Issues:"])

    file_issue_counts =
      issues
      |> Enum.group_by(& &1.filename)
      |> Enum.map(fn {filename, file_issues} ->
        {filename, Enum.count(file_issues)}
      end)
      |> Enum.sort_by(fn {_filename, count} -> count end, :desc)
      |> Enum.take(top_files_count)

    total_issues = Enum.count(issues)
    top_files_issues = file_issue_counts |> Enum.map(&elem(&1, 1)) |> Enum.sum()
    top_files_percentage =
      if total_issues > 0, do: Float.round(top_files_issues / total_issues * 100, 1), else: 0.0

    file_issue_counts
    |> Enum.with_index(1)
    |> Enum.reduce(0, fn {{filename, count}, index}, cumulative_count ->
      percentage = if total_issues > 0, do: Float.round(count / total_issues * 100, 1), else: 0.0
      new_cumulative = cumulative_count + count
      cumulative_percentage = if total_issues > 0, do: Float.round(new_cumulative / total_issues * 100, 1), else: 0.0

      UI.puts([
        "  ",
        :faint,
        String.pad_leading("#{index}.", 4),
        :reset,
        " ",
        :cyan,
        String.pad_trailing(Path.relative_to_cwd(filename), 60),
        :reset,
        " ",
        :bright,
        String.pad_leading("#{count}", 5),
        :reset,
        " (",
        :faint,
        "#{percentage}%",
        :reset,
        ", cumulative: ",
        :faint,
        "#{cumulative_percentage}%",
        :reset,
        ")"
      ])

      new_cumulative
    end)

    UI.puts()
    UI.puts([
      "  ",
      :bright,
      "Total in top #{top_files_count} files:",
      :reset,
      " ",
      :bright,
      "#{top_files_issues}",
      :reset,
      " / ",
      "#{total_issues}",
      " (",
      :faint,
      "#{top_files_percentage}%",
      :reset,
      ")"
    ])
  end

  defp get_top_files_count(%Execution{top_files: count})
       when is_integer(count) and count > 0 do
    count
  end

  defp get_top_files_count(_exec), do: 10
end
