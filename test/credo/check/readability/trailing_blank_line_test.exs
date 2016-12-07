defmodule Credo.Check.Readability.TrailingBlankLineTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.TrailingBlankLine

  #
  # cases NOT raising issues
  #

  test "it should NOT report expected code" do
"""
defmodule CredoSampleModule do
end
""" |> to_source_file
    |> refute_issues(@described_check)
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    "defmodule CredoSampleModule do\nend"
    |> to_source_file
    |> assert_issue(@described_check)
  end
end
