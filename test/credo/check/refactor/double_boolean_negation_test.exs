defmodule Credo.Check.Refactor.DoubleBooleanNegationTest do
  use Credo.TestHelper

  @described_check Credo.Check.Refactor.DoubleBooleanNegation

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    !true
    not true
    """
    |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    !!true
    """
    |> to_source_file
    |> assert_issue(@described_check, fn %Credo.Issue{trigger: trigger} ->
      assert "!!" == trigger
    end)
  end

  test "it should report a violation just once" do
    """
    !!!true
    """
    |> to_source_file
    |> assert_issue(@described_check, fn %Credo.Issue{trigger: trigger} ->
      assert "!!" == trigger
    end)
  end

  test "it should report a violation twice" do
    """
    !!!!true
    """
    |> to_source_file
    |> assert_issues(@described_check)
  end

  test "it should report a violation 2" do
    """
    not not true
    """
    |> to_source_file
    |> assert_issue(@described_check, fn %Credo.Issue{trigger: trigger} ->
      assert "not not" == trigger
    end)
  end
end
