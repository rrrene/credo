defmodule Credo.Check.Readability.ParenthesesInConditionTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.ParenthesesInCondition

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

  test "it should report violations with spaces before the parentheses" do
"""
defmodule Mix.Tasks.Credo do
  def run(argv) do
    if ( allowed? ) do
      true
    else
      false
    end

    unless (also_allowed?) do
      true
    end
  end
end
""" |> to_source_file
    |> assert_issues(@described_check)
  end
end
