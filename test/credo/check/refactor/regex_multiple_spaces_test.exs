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

end
