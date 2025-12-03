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
    refute Enum.empty?(issues), "There should be one issue, got none."

    assert Enum.count(issues) == 1,
           "There should be only 1 issue, got #{Enum.count(issues)}:\n\n#{to_inspected(issues)}"

    if callback do
      issues |> List.first() |> callback.()
    end

    issues
  end

  def assert_issues(issues, callback \\ nil) do
    refute Enum.empty?(issues), "There should be multiple issues, got none."

    assert Enum.count(issues) > 1,
           "There should be more than one issue, got:\n\n#{to_inspected(issues)}"

    if callback, do: callback.(issues)

    issues
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
