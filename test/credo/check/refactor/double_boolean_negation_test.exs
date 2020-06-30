defmodule Credo.Check.Refactor.DoubleBooleanNegationTest do
  use Credo.Test.Case

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
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    """
    !!true
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn %Credo.Issue{trigger: trigger} ->
      assert "!!" == trigger
    end)
  end

  test "it should report a violation just once" do
    """
    !!!true
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn %Credo.Issue{trigger: trigger} ->
      assert "!!" == trigger
    end)
  end

  test "it should report a violation twice" do
    """
    !!!!true
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should report a violation 2" do
    """
    not not true
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn %Credo.Issue{trigger: trigger} ->
      assert "not not" == trigger
    end)
  end
end
