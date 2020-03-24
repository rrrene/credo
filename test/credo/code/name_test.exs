defmodule Credo.Code.NameTest do
  use Credo.Test.Case

  alias Credo.Code.Name

  #
  # last
  #

  test "returns last name when atom provided" do
    name = Credo.Code.Module

    expected = "Module"
    assert name |> Name.last() == expected
  end

  test "returns last name when binary provided" do
    name = "Credo.Code.Module"

    expected = "Module"
    assert name |> Name.last() == expected
  end

  test "returns last name when list provided" do
    mod_list = [:Credo, :Code, :Module]

    expected = "Module"
    assert mod_list |> Name.last() == expected
  end

  #
  # first
  #

  test "returns first name when atom provided" do
    name = Credo.Code.Module

    expected = "Credo"
    assert name |> Name.first() == expected
  end

  test "returns first name when binary provided" do
    name = "Credo.Code.Module"

    expected = "Credo"
    assert name |> Name.first() == expected
  end

  test "returns first name when list provided" do
    mod_list = [:Credo, :Code, :Module]

    expected = "Credo"
    assert mod_list |> Name.first() == expected
  end

  #
  # full
  #

  test "returns full name when atom provided" do
    name = Credo.Code.Module

    expected = "Credo.Code.Module"
    assert name |> Name.full() == expected
  end

  test "returns full name when binary provided" do
    name = "Credo.Code.Module"

    expected = "Credo.Code.Module"
    assert name |> Name.full() == expected
  end

  test "returns full name when list provided" do
    mod_list = [:Credo, :Code, :Module]

    expected = "Credo.Code.Module"
    assert mod_list |> Name.full() == expected
  end

  test "returns full name for list containing module attribute" do
    mod_list = [{:@, [line: 2], [{:credo_code, [line: 2], nil}]}, :Module]

    expected = "@credo_code.Module"
    assert mod_list |> Name.full() == expected
  end

  test "returns full name for list containing unquote" do
    mod_list = [
      {:unquote, [line: 62], [{:credo_code, [line: 62], nil}]},
      :Module
    ]

    expected = "unquote(credo_code).Module"
    assert mod_list |> Name.full() == expected
  end

  test "returns full name for a function call" do
    mod_list = [
      {:my_fun, [line: 62], [{:param1, [line: 62], nil}, {:param2, [line: 62], nil}]},
      :Module
    ]

    expected = "my_fun(param1, param2).Module"
    assert mod_list |> Name.full() == expected
  end

  #
  # parts_count
  #

  test "returns parts_count when list provided" do
    name = "Credo.Code.Module"

    expected = 3
    assert name |> Name.parts_count() == expected
  end

  #
  # snake_case?
  #

  test "returns true if name is snake_case" do
    assert "snake_case_test" |> Name.snake_case?()
    assert "snake_case23" |> Name.snake_case?()
    assert "snake_case_23" |> Name.snake_case?()
    assert "latency_μs" |> Name.snake_case?()
    assert "rené_föhring" |> Name.snake_case?()
    refute "SnakeCase_mixed" |> Name.snake_case?()
  end

  #
  # no_case?
  #

  test "returns true if name is no_case" do
    assert "..." |> Name.no_case?()
    refute "SnakeCase_mixed" |> Name.no_case?()
  end

  #
  # pascal_case?
  #

  test "returns true if name is pascal_case" do
    assert "PascalCaseTest" |> Name.pascal_case?()
    refute "SnakeCase_mixed" |> Name.pascal_case?()
  end

  #
  # split_pascal_case
  #

  test "returns the parts of a PascalCased name as list" do
    assert ["Pascal", "Case", "Test"] == Name.split_pascal_case("PascalCaseTest")
  end
end
