defmodule Credo.Check.Consistency.SpaceAroundOperators.WithSpaceTest do
  use Credo.TestHelper

  alias Credo.Check.Consistency.SpaceAroundOperators.WithSpace

  @without_spaces """
defmodule Credo.Sample1 do
  defmodule InlineModule do
    def foobar do
      1+2
    end
  end
end
"""
  @with_spaces """
defmodule Credo.Sample2 do
  defmodule InlineModule do
    def foobar do
      4 + 3
      4 - 3
      4 * 3
      a = 3
      4 && 3
      "4" <> "3"
      4 == 3
      [4] ++ [3]
      4 == 3
      4 > 3
      4 >= 3
      4 <= 3
      for file <- files do
      end
      something = removed != []
      Enum.map(dep.deps, &(&1.app)) ++ current_breadths
    end
  end
end
"""
  test "it should NOT report anything" do
    result =
      @without_spaces
      |> to_source_file()
      |> WithSpace.property_value_for([])
      |> Enum.reject(&is_nil/1)

    assert [] == result
  end

  test "it should report the correct property values" do
    result =
      @with_spaces
      |> to_source_file()
      |> WithSpace.property_value_for([])
      |> Enum.reject(&is_nil/1)

    assert 16 == Enum.count(result)
  end

end
