defmodule Credo.PriorityTest do
  use Credo.TestHelper

  alias Credo.Priority

  test "it should NOT report expected code 2" do
    source_file = """
defmodule Credo.Sample.Module do
  def some_function(p1, p2, p3, p4, p5) do
    some_value = parameter1 + parameter2
  end
end
""" |> to_source_file
    expected = %{
      "Credo.Sample.Module" => 1,
      "Credo.Sample.Module.some_function" => 4
    }
    assert expected == Priority.scope_priorities(source_file)
  end

  test "it should assign priorities based on many_functions" do
    source_file = """
defmodule Credo.Sample.Module do
  def fun0, do: 1
  def fun1(p1), do: 2
  def fun2(p1, p2), do: 3
  def fun3(p1, p2, p3), do: 4
  def fun4(p1, p2, p3, p4), do: 5
  def fun5(p1, p2, p3, p4, p5), do: 5
end
""" |> to_source_file

    expected = %{
      "Credo.Sample.Module" => 2,
      "Credo.Sample.Module.fun0" => 2+0,
      "Credo.Sample.Module.fun1" => 2+1,
      "Credo.Sample.Module.fun2" => 2+1,
      "Credo.Sample.Module.fun3" => 2+2,
      "Credo.Sample.Module.fun4" => 2+2,
      "Credo.Sample.Module.fun5" => 2+3
    }
    assert expected == Priority.scope_priorities(source_file)
  end

  test "it should not crash if @def_ops attributes provided and and should return correct scope_priorities" do
    source_file = """
defmodule Credo.Sample.Module do
  @def \"""
  Returns a list of `TimeSlice` structs based on the provided `time_slice_selector`.
  \"""
  def fun0, do: 1
  def fun1(p1), do: 2
  def fun2(p1, p2), do: 3
  def fun3(p1, p2, p3), do: 4
  def fun4(p1, p2, p3, p4), do: 5
  def fun5(p1, p2, p3, p4, p5), do: 5
  def fun6(p1, p2, p3, p4, p5) do
    5
  end

  @defp "and another strange module attribute"
  @defmacro "and another one"
end
""" |> to_source_file

    expected = %{
      "Credo.Sample.Module" => 2,
      "Credo.Sample.Module.fun0" => 2+0,
      "Credo.Sample.Module.fun1" => 2+1,
      "Credo.Sample.Module.fun2" => 2+1,
      "Credo.Sample.Module.fun3" => 2+2,
      "Credo.Sample.Module.fun4" => 2+2,
      "Credo.Sample.Module.fun5" => 2+3,
      "Credo.Sample.Module.fun6" => 2+3
    }
    assert expected == Priority.scope_priorities(source_file)
  end
end
