defmodule Credo.Check.Readability.TrailingBlankLineTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.TrailingBlankLine

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
    """
    defmodule CredoSampleModule do
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
    "defmodule CredoSampleModule do\nend"
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue()
  end
end
