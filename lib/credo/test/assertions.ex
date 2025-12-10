defmodule Credo.Test.Assertions do
  @moduledoc false

  import ExUnit.Assertions
  import IO.ANSI

  def assert_trigger(issue, trigger)

  def assert_trigger([issue], trigger), do: [assert_trigger(issue, trigger)]

  def assert_trigger(issue, trigger) do
    assert trigger == issue.trigger

    issue
  end

  def refute_issues(issues) do
    assert [] == issues,
           "#{red()}There should be no issues, got #{Enum.count(issues)}:#{reset()}\n\n#{to_inspected(issues) |> indent(4)}"

    issues
  end

  def assert_issue(issues, callback \\ nil) do
    refute match?([], issues), "#{red()}There should be one issue, got none."

    assert match?([_only_issue], issues),
           "#{red()}There should be only 1 issue, got #{Enum.count(issues)}:#{reset()}\n\n#{to_inspected(issues) |> indent(4)}"

    case callback do
      callback when is_function(callback) ->
        issues |> List.first() |> callback.()

      pattern when is_map(pattern) ->
        assert_issue_matches(issues, pattern)

      nil ->
        nil
    end

    issues
  end

  def assert_issues(issues) do
    assert_issues(issues, nil)
  end

  def assert_issues(issues, 0) do
    refute_issues(issues)
  end

  def assert_issues(issues, 1) do
    assert_issue(issues)
  end

  def assert_issues(issues, count) when is_integer(count) do
    assert_issues(issues, fn issues ->
      assert length(issues) == count,
             "#{red()}There should be #{count} issues, got #{length(issues)}."
    end)
  end

  def assert_issues(issues, callback)
      when (is_list(issues) and is_nil(callback)) or is_function(callback, 1) do
    refute match?([], issues), "#{red()}There should be multiple issues, got none."

    refute match?([_only_issue], issues),
           "#{red()}There should be more than one issue, got:#{reset()}\n\n#{to_inspected(issues) |> indent(4)}"

    if callback, do: callback.(issues)

    issues
  end

  def assert_issues_match(issues, patterns) do
    patterns
    |> List.wrap()
    |> Enum.each(&assert_issue_matches(issues, &1))

    pattern_count = length(patterns)
    issue_count = length(issues)

    assert pattern_count == issue_count,
           "#{red()}All patterns matched, but there are #{pattern_count} patterns and #{issue_count} issues."

    issues
  end

  def assert_issue_matches(issues, pattern) do
    assert matches_any_issue?(issues, pattern), assert_issue_matches_message(issues, pattern)

    issues
  end

  defp assert_issue_matches_message(issues, pattern) do
    non_matching_fields =
      Enum.map(pattern, fn {key, value} ->
        if not matches_any_issue?(issues, Map.new([{key, value}])) do
          {key, value}
        end
      end)
      |> Enum.reject(&is_nil/1)

    inspected_pattern =
      pattern
      |> inspect(pretty: true)
      |> indent(4)
      |> highlight_fields_in_inspected_pattern(non_matching_fields)

    """
    #{red()}
    No issue found matching this pattern:
    #{reset()}
    #{inspected_pattern}

    Issues:

    #{to_inspected(issues) |> indent(4)}
    """
    |> String.trim_leading()
  end

  defp highlight_fields_in_inspected_pattern(inspected_pattern, fields) do
    Enum.reduce(fields, inspected_pattern, fn {key, _}, memo ->
      String.replace(
        memo,
        ~r/(\s*)(#{key}:)(.+)$/mi,
        "\\1#{red()}\\2#{reset()}\\3#{faint()} # <-- matches no issue#{reset()}"
      )
    end)
  end

  defp matches_any_issue?(issues, pattern) do
    Enum.any?(issues, &matches_issue?(&1, pattern))
  end

  defp matches_issue?(issue, pattern) do
    {pretest?, pattern} =
      case pattern[:message] do
        nil -> {true, pattern}
        message -> {matches_message?(issue, message), Map.drop(pattern, [:message])}
      end

    pretest? && Map.equal?(pattern, Map.intersect(pattern, issue))
  end

  defp matches_message?(issue, "" <> message) do
    issue.message == message
  end

  defp matches_message?(issue, %Regex{} = message) do
    issue.message =~ message
  end

  def to_inspected(value) when is_list(value) do
    Enum.map_join(value, "\n", &to_inspected/1)
  end

  def to_inspected(%Credo.Issue{} = issue) do
    inspected =
      issue
      |> Inspect.Algebra.to_doc(%Inspect.Opts{})
      |> Inspect.Algebra.format(50)
      |> IO.iodata_to_binary()

    if Credo.Test.Case.test_source_files?() do
      """
      #{inspected}

      #{Credo.Test.Case.get_issue_inline(issue)}
      """
      |> String.trim()
    else
      inspected
    end
  end

  defp indent(string, count) do
    string
    |> String.split("\n")
    |> Enum.map(&"#{String.pad_leading("", count)}#{&1}")
    |> Enum.join("\n")
  end
end
