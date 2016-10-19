defmodule Credo.Check.Consistency.SpaceInParentheses.WithSpaceTest do
  use Credo.TestHelper

  alias Credo.Check.Consistency.SpaceInParentheses.WithSpace

  @without_spaces """
defmodule Credo.Sample1 do
  defmodule InlineModule do
    def foobar do
      {:ok} = File.read(filename)
      {
        :multi_line_tuple,
        File.read(filename) # completely fine
      }
    end
  end
end
"""
  @with_spaces """
defmodule Credo.Sample2 do
  defmodule InlineModule do
    def foobar do
      { :ok } = File.read( filename )
    end
  end
end
"""

  @heredoc_example """
string = ~s\"\"\"
  "[]"
\"\"\"

another_string = ~s\"\"\"
  "[ ]"
\"\"\"
  """

  test "it should report the correct most picked prop_value" do
    result =
      @without_spaces
      |> to_source_file()
      |> WithSpace.property_value_for([])
      |> Enum.reject(&is_nil/1)

    assert [] == result
  end


  test "it should report the correct property values with_space" do
    result =
      @with_spaces
      |> to_source_file()
      |> WithSpace.property_value_for([])
      |> Enum.reject(&is_nil/1)

    assert 1 == Enum.count(result)
  end

  test "it should NOT report an error when heredoc contains sigil chars" do
    errors = @heredoc_example
      |> to_source_file
      |> WithSpace.property_value_for([])
      |> Enum.reject(&is_nil/1)

    assert [] == errors
  end

end
