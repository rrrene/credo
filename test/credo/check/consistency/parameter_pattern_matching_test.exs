defmodule Credo.Check.Readability.ParameterPatternMatchingTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.ParameterPatternMatching
  @left_and_right_mix """
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

  @var_left_list """
  defmodule Test do
    def test(foo = [x, y, x]) do
      nil
    end
  end
"""
  @var_left_struct """
  defmodule Test do
    def test(foo = %Foo{hello: "world"}) do
      nil
    end
  end
"""
  @var_left_map """
  defmodule Test do
    def test(foo = %{abc: def}) do
      nil
    end
  end
"""

  @var_right_list """
    defmodule Test do
      def test([x, y, x] = foo) do
        nil
      end
    end
  """
  @var_right_struct """
  defmodule Test do
    def test(%Foo{hello: "world"} = foo) do
      nil
    end
  end
"""
  @var_right_map """
  defmodule Test do
    def test(%{abc: def} = foo) do
      nil
    end
  end
"""

  test "it should report errors when variable decalrations are mixed on the left and right side when pattern matching" do
    [@left_and_right_mix]
    |> to_source_files
    |> assert_issues(@described_check)
  end

  test "it should NOT report errors when variable decalrations are consistently on the left side" do
    [@var_left_map, @var_left_struct, @var_left_list]
    |> to_source_files
    |> refute_issues(@described_check)
  end


  test "it should NOT report errors when variable decalrations are consistently on the right side" do
    [@var_right_map, @var_right_struct, @var_right_list]
    |> to_source_files
    |> refute_issues(@described_check)
  end

  test "it should report errors when variable decalrations are inconsistent throughout sourcefiles" do
    [@var_right_map, @var_right_struct, @var_right_list, @var_left_map, @var_left_struct, @var_left_list]
    |> to_source_files
    |> assert_issues(@described_check)
  end
end
