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
           "There should be no issues, got #{Enum.count(issues)}: #{to_inspected(issues)}"

    issues
  end

  def assert_issue(issues, callback \\ nil) do
    refute Enum.empty?(issues), "There should be one issue, got none."

    assert Enum.count(issues) == 1,
           "There should be only 1 issue, got #{Enum.count(issues)}: #{to_inspected(issues)}"

    if callback do
      issues |> List.first() |> callback.()
    end

    issues
  end

  def assert_issues(issues, callback \\ nil) do
    assert Enum.count(issues) > 0, "There should be multiple issues, got none."

    assert Enum.count(issues) > 1,
           "There should be more than one issue, got: #{to_inspected(issues)}"

    if callback, do: callback.(issues)

    issues
  end

  def to_inspected(value) do
    value
    |> Inspect.Algebra.to_doc(%Inspect.Opts{})
    |> Inspect.Algebra.format(50)
    |> Enum.join("")
  end
end
