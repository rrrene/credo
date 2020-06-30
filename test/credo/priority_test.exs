defmodule Credo.PriorityTest do
  use Credo.Test.Case

  alias Credo.Priority

  test "it should return 0 for nil" do
    assert 0 == Priority.to_integer(nil)
  end

  test "it should return numbers" do
    assert 42 == Priority.to_integer(42)
    assert -42 == Priority.to_integer(-42)
  end

  test "it should return numbers given as binaries" do
    assert -42 == Priority.to_integer("-42")
  end

  test "it should look up aliases given as binaries" do
    assert is_number(Priority.to_integer("normal"))
    assert is_number(Priority.to_integer("high"))
    assert Priority.to_integer("normal") != assert(Priority.to_integer("high"))
  end

  test "it should look up aliases given as atoms" do
    assert is_number(Priority.to_integer(:normal))
    assert is_number(Priority.to_integer(:high))
    assert Priority.to_integer(:normal) != assert(Priority.to_integer(:high))
  end

  test "it should raise for strings" do
    assert_raise(RuntimeError, fn -> Priority.to_integer("-123.32") end)
  end

  test "it should raise when the lookup fails" do
    assert_raise(RuntimeError, fn -> Priority.to_integer("foobar") end)
    assert_raise(RuntimeError, fn -> Priority.to_integer(:foobar) end)
  end

  test "it should NOT report expected code 2" do
    source_file =
      """
      defmodule Credo.Sample.Module do
        def some_function(p1, p2, p3, p4, p5) do
          some_value = parameter1 + parameter2
        end
      end
      """
      |> to_source_file

    expected = %{
      "Credo.Sample.Module" => 1,
      "Credo.Sample.Module.some_function" => 4
    }

    assert expected == Priority.scope_priorities(source_file)
  end

  test "it should assign priorities based on many_functions" do
    source_file =
      """
      defmodule Credo.Sample.Module do
        def fun0, do: 1
        def fun1(p1), do: 2
        def fun2(p1, p2), do: 3
        def fun3(p1, p2, p3), do: 4
        def fun4(p1, p2, p3, p4), do: 5
        def fun5(p1, p2, p3, p4, p5), do: 5
      end
      """
      |> to_source_file

    expected = %{
      "Credo.Sample.Module" => 2,
      "Credo.Sample.Module.fun0" => 2 + 0,
      "Credo.Sample.Module.fun1" => 2 + 1,
      "Credo.Sample.Module.fun2" => 2 + 1,
      "Credo.Sample.Module.fun3" => 2 + 2,
      "Credo.Sample.Module.fun4" => 2 + 2,
      "Credo.Sample.Module.fun5" => 2 + 3
    }

    assert expected == Priority.scope_priorities(source_file)
  end

  test "it should not crash if @def_ops attributes provided and and should return correct scope_priorities" do
    source_file =
      """
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
      """
      |> to_source_file

    expected = %{
      "Credo.Sample.Module" => 2,
      "Credo.Sample.Module.fun0" => 2 + 0,
      "Credo.Sample.Module.fun1" => 2 + 1,
      "Credo.Sample.Module.fun2" => 2 + 1,
      "Credo.Sample.Module.fun3" => 2 + 2,
      "Credo.Sample.Module.fun4" => 2 + 2,
      "Credo.Sample.Module.fun5" => 2 + 3,
      "Credo.Sample.Module.fun6" => 2 + 3
    }

    assert expected == Priority.scope_priorities(source_file)
  end
end
