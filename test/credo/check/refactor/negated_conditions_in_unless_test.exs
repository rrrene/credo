defmodule Credo.Check.Refactor.NegatedConditionsInUnlessTest do
  use Credo.TestHelper

  @described_check Credo.Check.Refactor.NegatedConditionsInUnless

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    unless allowed? do
      something
    end
    if !allowed? do
      something
    end
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    unless !allowed? do
      something
    end
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end
end
