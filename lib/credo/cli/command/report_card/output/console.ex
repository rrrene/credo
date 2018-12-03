defmodule Credo.CLI.Command.ReportCard.Output.Console do
  @moduledoc false

  alias Credo.Execution

  def print_before_info(_source_files, _exec), do: nil

  def print_after_info(_source_files, exec, _time_load, _time_run) do
    exec
    |> Execution.get_issues()
    |> print_issues()
  end

  alias Credo.CLI.Output.UI

  defp print_issues(issues) do
    UI.puts()

    issues
    |> Enum.reduce(Map.new(), &Credo.CLI.Output.Formatter.ReportCard.categorize_module/2)
    |> Enum.map(&score_module/1)
    |> Enum.sort_by(fn {n, g, rs, ic} -> {g, rs, ic, n} end)
    |> Enum.reverse()
    |> Enum.each(fn item -> write_console(item) end)
  end

  defp write_console({n, g, rs, ic}) do
    {grade_bg, grade_fg} = grade_colors(g)

    UI.puts([
      grade_bg,
      grade_fg,
      " ",
      g,
      " ",
      :reset,
      " ",
      n
    ])

    UI.puts(["    ", "Issues: ", Integer.to_string(ic)])

    UI.puts([
      "    ",
      "Remediation Time: ",
      Credo.CLI.Output.Formatter.ReportCard.format_remediation_time(rs)
    ])

    UI.puts()
  end

  defp score_module({k, v}) do
    {issue_count, raw_score} = Credo.CLI.Output.Formatter.ReportCard.score_issues(k, v)
    mod_grade = Credo.CLI.Output.Formatter.ReportCard.grade(raw_score)
    {k, mod_grade, raw_score, issue_count}
  end

  defp grade_colors("A") do
    {:green_background, :bright}
  end

  defp grade_colors("B") do
    {:magenta_background, :bright}
  end

  defp grade_colors("C") do
    {:blue_background, :bright}
  end

  defp grade_colors("D") do
    {:yellow_background, :bright}
  end

  defp grade_colors("E") do
    {:orange_background, :bright}
  end

  defp grade_colors(_) do
    {:red_background, :bright}
  end
end
