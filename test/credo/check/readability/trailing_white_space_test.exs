defmodule Credo.Check.Readability.TrailingWhiteSpaceTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.TrailingWhiteSpace

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
    "defmodule CredoSampleModule do\n@test true   \nend"
    |> to_source_file
    |> assert_issue(@described_check, fn(issue) ->
        assert 11 == issue.column
        assert "   " == issue.trigger
      end)
  end

  test "it should report multiple violations" do
    "defmodule CredoSampleModule do   \n@test true   \nend"
    |> to_source_file
    |> assert_issues(@described_check)
  end
end
