defmodule Main do
  import IO.ANSI

  def run do
    {data, exit_status} =
      System.cmd("diff", ~w(tmp/old_credo.jsonl tmp/new_credo.jsonl))

    diff_lines =
      data
      |> String.split("\n")
      |> Enum.filter(fn
        "> " <> line -> true
        "< " <> line -> true
        line -> false
      end)

    issues = Enum.map(diff_lines, &to_issue/1)

    added_issues = Enum.filter(issues, &(&1.kind == "added")) |> Enum.map(& &1.issue)
    removed_issues = Enum.filter(issues, &(&1.kind == "removed")) |> Enum.map(& &1.issue)

    new_issues =
      Enum.filter(added_issues, fn current_issue ->
        not Enum.any?(removed_issues, &same_issue?(current_issue, &1))
      end)

    updated_issues =
      Enum.filter(added_issues, fn current_issue ->
        Enum.any?(removed_issues, &same_issue?(current_issue, &1))
      end)

    actually_removed_issues = removed_issues -- updated_issues

    new_categories = Enum.map(new_issues, & &1.category) |> Enum.uniq()
    updated_categories = Enum.map(updated_issues, & &1.category) |> Enum.uniq()

    new_checks = Enum.map(new_issues, & &1.check) |> Enum.uniq()
    updated_checks = Enum.map(updated_issues, & &1.check) |> Enum.uniq()

    Enum.each(issues, fn issue ->
      IO.puts(to_line(issue))
    end)

    IO.puts("")
    IO.puts("Issues: #{green()}+#{length(added_issues)} #{red()}-#{length(removed_issues)}")
    IO.puts("#{reset()}")

    IO.puts("#{bright()}#{yellow()}CHANGED: #{length(updated_issues)} issues")
    IO.puts("#{reset()}")

    print_issue_lists(updated_issues, yellow())

    IO.puts("#{bright()}#{cyan()}NEW: #{length(new_issues)} issues")
    IO.puts("#{reset()}")

    print_issue_lists(new_issues, cyan())
    IO.puts("#{reset()}")

    IO.puts("#{bright()}#{red()}Actually removed: #{length(actually_removed_issues)} issues")
    IO.puts("#{reset()}")

    print_issue_lists(actually_removed_issues, red())
    IO.puts("#{reset()}")

    exit({:shutdown, exit_status})
  end

  defp print_issue_lists(updated_issues, head_color \\ "") do
    updated_issues
    |> Enum.group_by(& &1.check)
    |> Enum.each(fn {check, issues} ->
      IO.puts("  #{head_color}■ #{check}")
      IO.puts("#{reset()}")

      max = 6
      length = length(issues)

      issues
      |> Enum.slice(0..(max - 1))
      |> Enum.each(fn issue ->
        IO.puts("  - " <> to_line(issue, false))
      end)

      if length > max do
        IO.puts("    #{faint()}(... #{length - max} more issues)")
      end

      IO.puts("#{reset()}")
    end)
  end

  defp to_issue("> " <> line) do
    %{kind: "added", issue: to_issue(:json.decode(line))}
  end

  defp to_issue("< " <> line) do
    %{kind: "removed", issue: to_issue(:json.decode(line))}
  end

  defp same_issue?(current_issue, %{} = previous_issue) do
    same_file_or_same_line? =
      current_issue.filename == previous_issue.filename || current_issue.line_no == previous_issue.line_no

    same_file_or_same_line? &&
      current_issue.category == previous_issue.category &&
      current_issue.message == previous_issue.message &&
      current_issue.trigger == previous_issue.trigger &&
      current_issue.scope == previous_issue.scope
  end

  defp to_issue(%{
         "category" => category,
         "check" => check,
         "column" => column,
         "column_end" => _,
         "filename" => filename,
         "line_no" => line_no,
         "message" => message,
         "priority" => _,
         "scope" => scope,
         "trigger" => trigger
       }) do
    %{
      category: category,
      check: check,
      column: column,
      filename: filename,
      line_no: line_no,
      message: message,
      scope: scope,
      trigger: trigger
    }
  end

  defp to_line(%{
         kind: kind,
         issue: issue
       }) do
    marker =
      case kind do
        "added" -> ">"
        "removed" -> "<"
      end

    "#{marker} #{to_line(issue)}"
  end

  defp to_line(
         %{
           category: category,
           check: check,
           column: column,
           filename: filename,
           line_no: line_no,
           message: message,
           scope: scope,
           trigger: trigger
         },
         include_check \\ true
       ) do
    file_slug =
      cond do
        line_no && column -> "#{filename}:#{line_no}:#{column}"
        line_no -> "#{filename}:#{line_no}"
        true -> filename
      end

    suffix =
      if include_check do
        " [#{check}]"
      else
        ""
      end

    "#{file_slug} #{message}" <> suffix
  end
end

Main.run()
