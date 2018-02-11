defmodule Credo.Check.Readability.SpaceAroundOperatorsTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.SpaceAroundOperators

  #
  # cases NOT raising issues
  #

  test "it should NOT report when op_pipe has spaces" do
    """
    defmodule CredoSampleModule do
      [1 | [2, 3]]
    end
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end


  #
  # cases raising issues
  #

  test "it should report when op_pipe has no spaces" do
    """
    defmodule CredoSampleModule do
      [1|[2, 3]]
    end
    """
    |> to_source_file
    |> assert_issue(@described_check, fn issue ->
      assert 5 == issue.column
      assert :| == issue.trigger
    end)
  end

  test "it should report when op_pipe has a space only" do
    """
    defmodule CredoSampleModule do
      [1 |[2, 3]]
    end
    """
    |> to_source_file
    |> assert_issue(@described_check, fn issue ->
      assert 6 == issue.column
      assert :| == issue.trigger
    end)
  end
end
