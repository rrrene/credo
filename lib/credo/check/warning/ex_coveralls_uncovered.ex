defmodule Credo.Check.Warning.ExCoverallsUncovered do
  @moduledoc false

  @checkdoc """
  Code should be touched at least once by code coverage.
  """
  @explanation [check: @checkdoc]

  use Credo.Check, base_priority: :high

  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    case Credo.Service.ExcoverallsMissingCoverage.data_available?() do
      false ->
        []

      _ ->
        check_coveralls_map(
          issue_meta,
          Credo.Service.ExcoverallsMissingCoverage.coverage_map(),
          source_file.filename
        )
    end
  end

  defp check_coveralls_map(issue_meta, coveralls_map, source_file) do
    {:ok, data} = Credo.Service.SourceFileLines.get(source_file)

    all_issues =
      Enum.reduce(data, [], fn {idx, _}, acc ->
        case line_in_missing_list(coveralls_map, source_file, idx) do
          true -> [issue_for(issue_meta, idx) | acc]
          _ -> acc
        end
      end)

    contract_issues(all_issues)
  end

  def contract_issues(all_issues) do
    sorted_issues =
      all_issues
      |> Enum.sort_by(fn issue -> issue.line_no end)

    {last, issues} =
      Enum.reduce(sorted_issues, {nil, []}, fn issue, acc ->
        reduce_issue_if_adjacent(issue, acc)
      end)

    finalize_join(issues, last)
  end

  defp reduce_issue_if_adjacent(issue, {nil, issues}) do
    {issue, issues}
  end

  defp reduce_issue_if_adjacent(issue, {last, issues}) do
    difference = issue.line_no - (last.line_no + last.severity - 1)

    case difference < 2 do
      false -> {issue, [last | issues]}
      _ -> {merge_issues(last, issue), issues}
    end
  end

  defp merge_issues(previous, _) do
    %Credo.Issue{previous | severity: previous.severity + 1}
  end

  defp finalize_join(issues, nil) do
    issues
  end

  defp finalize_join(issues, last) do
    [last | issues]
  end

  defp line_in_missing_list(coveralls_map, sf, idx) do
    case Map.has_key?(coveralls_map, sf) do
      false -> false
      _ -> Map.has_key?(Map.fetch!(coveralls_map, sf), idx)
    end
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "Code has no test coverage.",
      line_no: line_no,
      severity: 1
    )
  end
end
