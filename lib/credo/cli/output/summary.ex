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

    UI.puts()
    UI.puts([:faint, @cry_for_help])
    UI.puts()
    UI.puts([:faint, format_time_spent(checks_count, source_file_count, time_load, time_run)])

    UI.puts(summary_parts(source_files, issues))
    UI.puts()

    print_priority_hint(exec)
    print_first_run_hint(exec)
  end

  defp latest_tag do
    case System.cmd("git", ~w"describe --tags --abbrev=0") do
      {output, 0} -> String.trim(output)
      _ -> nil
    end
  end

  defp default_branch do
    remote_name = default_remote_name()

    case System.cmd("git", ~w"symbolic-ref refs/remotes/#{remote_name}/HEAD") do
      {output, 0} -> Regex.run(~r"refs/remotes/#{remote_name}/(.+)$", output) |> Enum.at(1)
      _ -> nil
    end
  end

  defp default_remote_name do
    "origin"
  end

  defp latest_commit_on_default_branch do
    case System.cmd("git", ~w"rev-parse --short #{default_remote_name()}/#{default_branch()}") do
      {output, 0} -> String.trim(output)
      _ -> nil
    end
  end

  defp now do
    DateTime.utc_now()
    |> Calendar.strftime("%Y-%m-%d")
  end

  defp print_first_run_hint(%Execution{cli_options: %{switches: %{first_run: true}}}) do
    term_width = Output.term_columns()
    now = now()
    default_branch = default_branch()
    latest_commit_on_default_branch = latest_commit_on_default_branch()
    latest_tag = latest_tag()

    headline = " 8< "
    bar = String.pad_leading("", div(term_width - String.length(headline), 2), "-")

    UI.puts()
    UI.puts()
    UI.puts([:magenta, :bright, "#{bar} 8< #{bar}"])
    UI.puts()
    UI.puts()

    UI.puts([
      :reset,
      :orange,
      """
      # Where to start?
      """,
      :reset,
      """

      That's a lot of issues to deal with at once.
      """,
      """

      You can use `diff` to only show the issues that were introduced on this branch:
      """,
      :cyan,
      """

          mix credo diff #{default_branch}

      """,
      :reset,
      :orange,
      """
      ## Compare to a point in history
      """,
      :reset,
      """

      You can use `diff` to only show the issues that were introduced after a certain tag or commit:

      """,
      :cyan,
      "    mix credo diff #{latest_tag} ",
      :faint,
      "             # use the latest tag",
      "\n\n",
      :reset,
      :cyan,
      "    mix credo diff #{latest_commit_on_default_branch}",
      :faint,
      "             # use the current HEAD of #{default_branch()}",
      "\n\n",
      :reset,
      """
      Lastly, you can compare your working dir against this point in time:

      """,
      :cyan,
      "    mix credo diff --since #{now}",
      :faint,
      "  # use the current time",
      "\n\n",
      :reset,
      :orange,
      """
      ## Every project is different
      """,
      :reset,
      """

      This is true, especially when it comes to introducing code analysis to an existing codebase.
      Doing so should not be about following any "best practice" in particular, it should be about
      helping you to get to know the ropes and make the changes you want.
      """
    ])

    UI.puts("Try the options outlined above to see which one is working for this project!")
  end

  defp print_first_run_hint(exec), do: exec

  defp count_checks(exec) do
    {result, _only_matching, _ignore_matching} = Execution.checks(exec)

    Enum.count(result)
  end

  defp print_priority_hint(%Execution{min_priority: min_priority})
       when min_priority >= 0 do
    UI.puts([
      :faint,
      "Showing priority issues: ↑ ↗ →  (use `mix credo explain` to explain issues, `mix credo --help` for options)."
    ])
  end

  defp print_priority_hint(_) do
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
    |> Enum.filter(&(&1.category == category))
    |> Enum.count()
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

  defp scope_count([]), do: 0

  defp scope_count(source_files) when is_list(source_files) do
    source_files
    |> Enum.map(&Task.async(fn -> scope_count(&1) end))
    |> Enum.map(&Task.await/1)
    |> Enum.reduce(&(&1 + &2))
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
end
