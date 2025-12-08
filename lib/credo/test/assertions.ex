defmodule Credo.Test.Assertions do
  @moduledoc false

  import ExUnit.Assertions

  def assert_trigger(issue, trigger)

  def assert_trigger([issue], trigger), do: [assert_trigger(issue, trigger)]

  def assert_trigger(issue, trigger) do
    assert trigger == issue.trigger

    issue
  end

  def refute_issues(issues) do
    assert [] == issues,
           "There should be no issues, got #{Enum.count(issues)}:\n\n#{to_inspected(issues)}"

    issues
  end

  def assert_issue(issues, callback \\ nil) do
    refute match?([], issues), "There should be one issue, got none."

    assert match?([_only_issue], issues),
           "There should be only 1 issue, got #{Enum.count(issues)}:\n\n#{to_inspected(issues)}"

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
      assert length(issues) == count, "There should be #{count} issues, got #{length(issues)}."
    end)
  end

  def assert_issues(issues, callback)
      when (is_list(issues) and is_nil(callback)) or is_function(callback, 1) do
    refute match?([], issues), "There should be multiple issues, got none."

    refute match?([_only_issue], issues),
           "There should be more than one issue, got:\n\n#{to_inspected(issues)}"

    if callback, do: callback.(issues)

    issues
  end

  def assert_issues_match(issues, patterns) do
    patterns
    |> List.wrap()
    |> Enum.each(&assert_issue_matches(issues, &1))

    issues
  end

  def assert_issue_matches(issues, pattern) do
    assert matches_any_issue?(issues, pattern),
           "No issue found matching:\n\n#{inspect(pattern, pretty: true)}\n\nIssues:\n\n#{to_inspected(issues)}"

    issues
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
    else
      inspected
    end
  end
end
