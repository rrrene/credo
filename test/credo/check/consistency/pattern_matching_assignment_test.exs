defmodule Credo.Check.Consistency.PatternMatchingAssignmentTest do
  use Credo.TestHelper

  @described_check Credo.Check.Consistency.PatternMatchingAssignment

  @left_side1 """
defmodule MyModule do
  def some_func1(a, b, foo = %{"foobar" => foobar}) do
    nil
  end

  def some_func2(a, b, foo = :some), do: nil
end
"""

  @right_side1 """
defmodule MyModule2 do
  defstruct name: "test"

  def some_func1(a, b, %MyModule2{name: "foobar"} = foo), do: nil

  def some_func2(a, b, %{"foobar" => foobar} = foo) do
    nil
  end
end
"""

  @left_right1 """
defmodule MyModule3 do
  defstruct name: "test"

  def some_func1(a, b, %{"foobar" => foobar} = foo), do: nil

  def some_func2(a, b, %{"foobar" => foobar} = foo) do
    nil
  end

  def some_func3(a, b, %MyModule3{name: foobar} = foo) do
    nil
  end

  def some_func1(a, b, foo = :test), do: nil

  def some_func2(a, b, foo = %{"foobar" => foobar}) do
    nil
  end
end
"""

  @left_right_one_line """
defmodule MyModule3 do
  defstruct name: "test"
  def some_func1(%{"foobar" => foo1} = foobar1, :test = foobar2, foobar3 = %MyModule3{name: foobar}), do: nil
end
"""

  test "it should report correct result" do
    [@left_side1]
    |> to_source_files
    |> refute_issues(@described_check)
  end

  test "it should report correct result 2" do
    [@right_side1]
    |> to_source_files
    |> refute_issues(@described_check)
  end

  test "it should report correct result 3" do
    [@left_right1]
    |> to_source_files
    |> assert_issues(@described_check)
  end

  test "it should report correct result for many assignments on one line 4" do
    [@left_right_one_line]
    |> to_source_files
    |> assert_issue(@described_check)
  end
end
