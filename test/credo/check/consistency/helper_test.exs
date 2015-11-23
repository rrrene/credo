defmodule Credo.Check.Consistency.HelperTest do
  use Credo.TestHelper

  alias Credo.Check.Consistency.Helper

  test "it should report the correct most picked prop_value" do
    prop_list = [
      {[:prop1, :prop2], "M1.ex"},
      {[:prop1], "M2.ex"},
      {[:prop1], "M3.ex"},
      {[:prop2], "M4.ex"},
      {[:prop1], "M5.ex"},
      {[:prop1, :prop2, :prop3], "M6.ex"},
    ]
    assert {:prop1, 5, 9} == Helper.most_picked_prop_value(prop_list)
  end

  test "it should report the correct most picked prop_value if its a keyword list" do
    prop_list = [
      {[[prefix: "Invalid"], [suffix: "Error"]], "M1.ex"},
      {[[prefix: "Invalid"]], "M2.ex"},
      {[[prefix: "Invalid"]], "M3.ex"},
      {[[suffix: "Error"]], "M4.ex"},
      {[[prefix: "Invalid"]], "M5.ex"},
      {[[prefix: "Invalid"], [suffix: "Error"], [prefix: "Undefined"]], "M6.ex"},
    ]
    assert {[prefix: "Invalid"], 5, 9} == Helper.most_picked_prop_value(prop_list)
  end

end
