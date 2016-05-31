defmodule Credo.Check.Refactor.RegexMultipleSpacesTest do
  use Credo.TestHelper

  @described_check Credo.Check.Refactor.RegexMultipleSpaces

  @moduletag :to_be_implemented

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  def my_fun do
    regex = ~r/foo {3}bar/
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report expected code /2" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    regex = ~r/foo   bar/
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end


  test "it should report a violation" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    if something? do
      parameter2
    else
      raise "error!!!"
      parameter1 + parameter2
    end
  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end
end
