defmodule Credo.Check.Warning.StructFieldAmountTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.StructFieldAmount

  @large_struct_module """
  defmodule MyApp.LargeStruct do
    defstruct field_1: "field_1",
              field_2: "field_2",
              field_3: "field_3",
              field_4: "field_4",
              field_5: "field_5",
              field_6: "field_6",
              field_7: "field_7",
              field_8: "field_8",
              field_9: "field_9",
              field_10: "field_10",
              field_11: "field_11",
              field_12: "field_12",
              field_13: "field_13",
              field_14: "field_14",
              field_15: "field_15",
              field_16: "field_16",
              field_17: "field_17",
              field_18: "field_18",
              field_19: "field_19",
              field_20: "field_20",
              field_21: "field_21",
              field_22: "field_22",
              field_23: "field_23",
              field_24: "field_24",
              field_25: "field_25",
              field_26: "field_26",
              field_27: "field_27",
              field_28: "field_28",
              field_29: "field_29",
              field_30: "field_30",
              field_31: "field_31",
              field_32: "field_32"
  end
  """

  @small_struct_module """
  defmodule MyApp.SmallStruct do
    defstruct [field_1: "field_1"]
  end
  """

  #
  # cases NOT raising issues
  #

  test "it should NOT report an issue if the struct has fewer than 32 fields" do
    [
      @small_struct_module
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report an issue if a struct has 32 or more fields" do
    [
      @large_struct_module
    ]
    |> to_source_files()
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert %{
               line_no: 1,
               message: "Struct %MyApp.LargeStruct{} found to have more than 32 fields."
             } = issue

      assert issue.trigger == "MyApp.LargeStruct do"
      assert issue.column == 11
    end)
  end
end
