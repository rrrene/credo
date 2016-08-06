defmodule Credo.Code.NameTest do
  use Credo.TestHelper

  alias Credo.Code.Name

  #
  # last
  #

  test "returns last name when atom provided" do
    name = Credo.Code.Module

    expected = "Module"
    assert name |> Name.last == expected
  end

  test "returns last name when binary provided" do
    name = "Credo.Code.Module"

    expected = "Module"
    assert name |> Name.last == expected
  end

  test "returns last name when list provided" do
    mod_list = [:Credo, :Code, :Module]

    expected = "Module"
    assert mod_list |> Name.last == expected
  end

  #
  # first
  #

  test "returns first name when atom provided" do
    name = Credo.Code.Module

    expected = "Credo"
    assert name |> Name.first == expected
  end

  test "returns first name when binary provided" do
    name = "Credo.Code.Module"

    expected = "Credo"
    assert name |> Name.first == expected
  end

  test "returns first name when list provided" do
    mod_list = [:Credo, :Code, :Module]

    expected = "Credo"
    assert mod_list |> Name.first == expected
  end

  #
  # full
  #

  test "returns full name when atom provided" do
    name = Credo.Code.Module

    expected = "Credo.Code.Module"
    assert name |> Name.full == expected
  end

  test "returns full name when binary provided" do
    name = "Credo.Code.Module"

    expected = "Credo.Code.Module"
    assert name |> Name.full == expected
  end

  test "returns full name when list provided" do
    mod_list = [:Credo, :Code, :Module]

    expected = "Credo.Code.Module"
    assert mod_list |> Name.full == expected
  end

  #
  # parts_count
  #

  test "returns parts_count when list provided" do
    name = "Credo.Code.Module"

    expected = 3
    assert name |> Name.parts_count == expected
  end

  #
  # snake_case?
  #

  test "returns true if name is snake_case" do
    assert "snake_case_test" |> Name.snake_case?
    refute "SnakeCase_mixed" |> Name.snake_case?
  end

  #
  # pascal_case?
  #

  test "returns true if name is pascal_case" do
    assert "PascalCaseTest" |> Name.pascal_case?
    refute "SnakeCase_mixed" |> Name.pascal_case?
  end

  #
  # split_pascal_case
  #

  test "returns the parts of a PascalCased name as list" do
    assert ["Pascal", "Case", "Test"] == Name.split_pascal_case("PascalCaseTest")
  end

end
