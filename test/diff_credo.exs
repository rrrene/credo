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
      added_issues
      |> Enum.map(fn current_issue ->
        old_issue = Enum.find(removed_issues, &same_issue?(current_issue, &1))

        Map.put(current_issue, :old_issue, old_issue)
      end)
      |> Enum.filter(fn %{old_issue: old_issue} -> not is_nil(old_issue) end)

    actually_removed_issues =
      Enum.filter(removed_issues, fn current_issue ->
        not Enum.any?(added_issues, &same_issue?(current_issue, &1))
      end)

    new_categories = Enum.map(new_issues, & &1.category) |> Enum.uniq()
    updated_categories = Enum.map(updated_issues, & &1.category) |> Enum.uniq()

    new_checks = Enum.map(new_issues, & &1.check) |> Enum.uniq() |> Enum.sort()
    updated_checks = Enum.map(updated_issues, & &1.check) |> Enum.uniq() |> Enum.sort()
    actually_removed_checks = Enum.map(actually_removed_issues, & &1.check) |> Enum.uniq() |> Enum.sort()

    Enum.each(issues, fn issue ->
      IO.puts(to_line(issue))
    end)

    IO.puts("")
    IO.puts("")
    IO.puts("#{green()}+#{length(added_issues)} #{red()}-#{length(removed_issues)}#{reset()} issues")
    IO.puts("#{reset()}")

    IO.puts("")
    IO.puts("#{bright()}#{yellow()}CHANGED: #{length(updated_issues)} issues")
    IO.puts("#{reset()}")

    print_issue_lists(updated_issues, yellow())

    IO.puts("")
    IO.puts("#{bright()}#{cyan()}NEW: #{length(new_issues)} issues")
    IO.puts("#{reset()}")

    print_issue_lists(new_issues, cyan())
    IO.puts("#{reset()}")

    IO.puts("")
    IO.puts("#{bright()}#{red()}Actually removed: #{length(actually_removed_issues)} issues")
    IO.puts("#{reset()}")

    print_issue_lists(actually_removed_issues, red())
    IO.puts("#{reset()}")

    if updated_checks != [] do
      IO.puts("#{bright()}#{yellow()}CHANGED:\n  - #{Enum.join(updated_checks, "\n  - ")}")
    end

    if new_checks != [] do
      IO.puts("#{bright()}#{cyan()}NEW:\n  - #{Enum.join(new_checks, "\n  - ")}")
    end

    if actually_removed_checks != [] do
      IO.puts("#{bright()}#{red()}Removed:\n  - #{Enum.join(actually_removed_checks, "\n  - ")}")
    end

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
        if issue[:old_issue] do
          IO.puts("  #{red()}- #{reset()}" <> to_line(issue[:old_issue], false) <> reset())
        end

        IO.puts("  #{green()}+ #{reset()}" <> to_line(issue, false))
        IO.puts(to_inspected(issue))
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

  def to_inspected(%{} = issue) do
    issue
    |> get_issue_inline()
    |> String.trim()
    |> indent(2)
  rescue
    e ->
      IO.warn(inspect(issue))
      reraise(e, __STACKTRACE__)
  end

  defp indent(string, count) do
    string
    |> String.split("\n")
    |> Enum.map(&"#{String.pad_leading("", count)}#{&1}")
    |> Enum.join("\n")
  end

  def get_issue_inline(issue, reset_color \\ :red) do
    source_line = get_source_line(issue)

    marker =
      if issue.line_no && issue.column && issue.trigger do
        String.duplicate(" ", issue.column - 1) <> String.duplicate("^", String.length(to_string(issue.trigger)))
      else
        ""
      end

    """
    #{cyan()}#{String.pad_leading("#{issue.line_no} |", 6)}#{format([reset_color])} #{source_line}
    #{cyan()}#{String.pad_leading("", 6)} #{marker}#{format([reset_color])}
    """
  end

  defp get_source_line(%{filename: filename, line_no: nil}) do
    nil
  end

  defp get_source_line(%{filename: filename, line_no: line_no}) do
    case File.read(filename) do
      {:ok, contents} -> contents |> String.split("\n") |> Enum.at(line_no - 1)
      _ -> nil
    end
  end

  defp same_issue?(current_issue, %{} = previous_issue) do
    same_file_or_same_line? =
      current_issue.filename == previous_issue.filename || current_issue.line_no == previous_issue.line_no

    same_file_or_same_line? &&
      current_issue.category == previous_issue.category &&
      current_issue.message == previous_issue.message &&
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
      column: can_be_nil(column),
      filename: filename,
      line_no: can_be_nil(line_no),
      message: message,
      scope: can_be_nil(scope),
      trigger: can_be_nil(trigger)
    }
  end

  defp can_be_nil(:null), do: nil
  defp can_be_nil(["__no_trigger__"]), do: nil
  defp can_be_nil(value), do: value

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

    "#{file_slug} #{faint()}#{message}" <> suffix
  end
end

Main.run()
