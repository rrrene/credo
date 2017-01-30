defmodule Credo.Check.Warning.MapGetUnsafePassTest do
  use Credo.TestHelper

  @described_check Credo.Check.Warning.MapGetUnsafePass

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    IO.inspect parameter1 + parameter2

    Map.get(%{}, :foo, [])
    |> Enum.map(&(&1))

  end
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should NOT report expected code 2" do
"""
defmodule CredoSampleModule do
def some_function(parameter1, parameter2) do
  IO.inspect parameter1 + parameter2

    %{}
    |> Map.get(:foo, [])
    |> Enum.each(&IO.puts/1)

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
  def some_function() do

    %{}
    |> Map.get(:foo)
    |> Map.put(:bar, "123")
    |> Enum.each(&IO.puts/1)

  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end


  test "it should report a violation /2" do
"""
defmodule CredoSampleModule do
  def some_function(parameter1, parameter2) do
    some_map = %{}

    Map.get(some_map, :items)
    |> Enum.map(fn x -> x["id"] end)

  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end


  test "it should report a violation /3" do
"""
defmodule CredoSampleModule do
  def some_function(a, b, c) do

    a
    |> Enum.map(fn x ->
                  x
                  |> Map.get(b)
                  |> String.to_int
                end)
    |> some_other_function(c)

  end
end
""" |> to_source_file
    |> assert_issue(@described_check)
  end
end
