defmodule Credo.Check.Warning.BoolOperationOnSameValuesTest do
  use Credo.TestHelper

  @described_check Credo.Check.Warning.BoolOperationOnSameValues

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case

  def some_fun do
    assert x && y
  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation for all defined operations" do
"""
defmodule CredoSampleModule do
  use ExUnit.Case

  def some_fun do
    x and x
    x or x
    x && x
    x || x
    x &&
      x # on different lines
  end
end
""" |> to_source_file
    |> assert_issues(@described_check, fn(issues) ->
        assert 5 == Enum.count(issues)
      end)
  end

end
