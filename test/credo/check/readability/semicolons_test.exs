defmodule Credo.Check.Readability.SemicolonsTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.Semicolons

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    def fun_name do
      statement1
      statement2
    end
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
    def fun_name() do
      statement1; statement2
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
