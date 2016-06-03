defmodule Credo.Check.Refactor.ParenthesesInConditionTest do
  use Credo.TestHelper

  @described_check Credo.Check.Refactor.ParenthesesInCondition

  @moduletag :to_be_implemented

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    unless allowed? do
      something
    end
    if !allowed? || (something_in_parentheses == 42) do
      something
    end
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should report a violation" do
"""
defmodule Mix.Tasks.Credo do
  def run(argv) do
    if( allowed? ) do
      true
    else
      false
    end
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end

  test "it should report a violation if used with parentheses" do
"""
defmodule Mix.Tasks.Credo do
  def run(argv) do
    unless( !allowed? ) do
      true
    else
      false
    end
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end
end
