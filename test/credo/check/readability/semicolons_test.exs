defmodule Credo.Check.Readability.SemicolonsTest do
  use Credo.TestHelper

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
    |> refute_issues(@described_check)
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
    |> assert_issue(@described_check)
  end
end
