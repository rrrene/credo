defmodule Credo.Check.Warning.StructFieldAmountTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.StructFieldAmount

  #
  # cases NOT raising issues
  #

  test "it should NOT report an issue if the struct has fewer than 32 fields" do
    """
    defmodule MyApp.SmallStruct do
      @moduledoc false

      defstruct [field_1: "field_1"]
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report an issue if the struct has fewer than 32 fields /2" do
    """
    defmodule MyApp.SmallStruct do
      @moduledoc false

      defstruct field_1: "field_1",
                field_2: "field_2",
                field_3: "field_3",
                field_4: "field_4",
                field_5: "field_5",
                field_6: "field_6",
                field_7: "field_7",
                field_8: "field_8",
                field_9: "field_9",
                field_10: "field_10"
    end
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report an issue if a struct has 32 or more fields" do
    """
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
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue(%{line_no: 2, column: 3, trigger: "defstruct"})
  end

  test "it should report an issue if the struct has more than :max_fields fields" do
    """
    defmodule MyApp.SmallStruct do
      @moduledoc false

      defstruct field_1: "field_1",
                field_2: "field_2",
                field_3: "field_3",
                field_4: "field_4",
                field_5: "field_5",
                field_6: "field_6",
                field_7: "field_7",
                field_8: "field_8",
                field_9: "field_9",
                field_10: "field_10"
    end
    """
    |> to_source_file()
    |> run_check(@described_check, max_fields: 8)
    |> assert_issue()
  end
end
