defmodule Credo.Check.Readability.PredicateFunctionNamesTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.PredicateFunctionNames

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    def valid? do
    end
    defp has_attachment? do
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
    def is_valid? do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report a violation /2" do
    """
    def is_valid do
    end
    defp is_attachment? do
    end
    """
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end
end
