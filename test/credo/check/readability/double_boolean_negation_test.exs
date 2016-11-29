defmodule Credo.Check.Readability.DoubleBooleanNegationTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.DoubleBooleanNegation

  test "it should NOT report expected code" do
"""
!true
not true
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  test "it should report a violation" do
"""
!!true
""" |> to_source_file
    |> assert_issue(@described_check, fn(%Credo.Issue{trigger: trigger}) ->
      assert "!!" == trigger
    end)
  end

  test "it should report a violation 2" do
"""
not not true
""" |> to_source_file
    |> assert_issue(@described_check, fn(%Credo.Issue{trigger: trigger}) ->
      assert "not not" == trigger
    end)
  end
end
