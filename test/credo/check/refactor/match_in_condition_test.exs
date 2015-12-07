defmodule Credo.Check.Refactor.MatchInConditionTest do
  use Credo.TestHelper

  @described_check Credo.Check.Refactor.MatchInCondition

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    if parameter1 == parameter2 do
      do_something
    end
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should report a violation" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    if {:ok, value} = parameter1 do
      do_something
    end
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation for :unless" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    unless {:ok, value} = parameter1 do
      do_something
    end
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end
end
