defmodule Credo.Check.Readability.ParameterPatternMatchingTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.ParameterPatternMatching
  @both """
defmodule Credo.Sample do
  defmodule InlineModule do
    
    def list_before(foo = [bar, baz]), do: :ok
    def list_after([bar, baz] = foo), do: :ok
    
    def struct_before(foo = %User{name: name}), do: :ok
    def struct_after(%User{name: name} = foo), do: :ok
      
    def map_before(foo = %{bar: baz}), do: :ok
    def map_after(%{bar: baz} = foo), do: :ok
  end
end
"""


  test "run it" do
    [
      @both
    ]
    |> to_source_files()
    |> refute_issues(@described_check)
  end

end

