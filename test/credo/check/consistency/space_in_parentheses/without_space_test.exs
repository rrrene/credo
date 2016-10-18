defmodule Credo.Check.Consistency.SpaceInParentheses.WithoutSpaceTest do
  use Credo.TestHelper

  alias Credo.Check.Consistency.SpaceInParentheses.WithoutSpace

  @with_spaces """
defmodule Credo.Sample2 do
  defmodule InlineModule do
    def foobar do
      { :ok } = File.read( filename )
    end
  end
end
"""
  @without_spaces """
defmodule Credo.Sample1 do
  defmodule InlineModule do
    @default_sources_glob ~w(** *.{ex,exs})

    def foobar do
      {:ok} = File.read(filename)
      {
        :multi_line_tuple,
        File.read(filename) # completely fine
      }
      parse_code(t, acc <> ~s(\"\"\"))
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
      @with_spaces
      |> to_source_file()
      |> WithoutSpace.property_value_for([])
      |> Enum.reject(&is_nil/1)

    assert [] == result
  end


  test "it should report the correct property values without_space" do
    result =
      @without_spaces
      |> to_source_file()
      |> WithoutSpace.property_value_for([])
      |> Enum.reject(&is_nil/1)

    assert 4 == Enum.count(result)
  end

  test "it should NOT report an error when heredoc contains sigil" do
    errors = @heredoc_example
      |> to_source_file
      |> WithoutSpace.property_value_for([])
      |> Enum.reject(&is_nil/1)

    assert [] == errors
  end


end
