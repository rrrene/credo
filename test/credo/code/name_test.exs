defmodule Credo.Code.NameTest do
  use Credo.TestHelper

  alias Credo.Code.Name

  test "returns true if name is snake_case" do
    assert "snake_case_test" |> Name.snake_case?
    refute "SnakeCase_mixed" |> Name.snake_case?
  end

  test "returns true if name is pascal_case" do
    assert "PascalCaseTest" |> Name.pascal_case?
    refute "SnakeCase_mixed" |> Name.pascal_case?
  end


  test "returns the parts of a PascalCased name as list" do
    assert ["Pascal", "Case", "Test"] == Name.split_pascal_case("PascalCaseTest")
  end

end
