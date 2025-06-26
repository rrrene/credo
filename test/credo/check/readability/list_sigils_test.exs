defmodule Credo.Check.Readability.ListSigilsTest do
  use Credo.Test.Case, async: true

  @described_check Credo.Check.Readability.ListSigils

  #
  # cases NOT raising issues
  #

  test "it should NOT report when no ~w or ~W sigil is used" do
    ~S"""
    ["foo", "bar", "baz"] == ["foo", "bar", "baz"]
    ["{\"key\":\"value\"}"] == [~S({"key":"value"})]
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report when a ~w sigil is used" do
    """
    ~w(foo bar baz) == ["foo", "bar", "baz"]
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end

  test "it should report when a ~W sigil is used" do
    """
    ~W({"key":"value"}) == [~S({"key":"value"})]
    """
    |> to_source_file()
    |> run_check(@described_check)
    |> assert_issue()
  end
end
