defmodule Credo.Check.Readability.StringSigilsTest do
  use Credo.TestHelper

  @described_check Credo.Check.Readability.StringSigils

  def create_snippet(string_literal) do
    """
    defmodule CredoTest do
      @module_var "#{string_literal}"
    end
    """
  end

  def create_sigil_snippet(string_literal, sigil \\ "s") do
    """
    defmodule CredoTest do
      @module_var ~#{sigil}(#{string_literal})
    end
    """
  end

  test "does NOT report for empty string" do
    create_snippet("")
      |> to_source_file
      |> refute_issues(@described_check)
  end

  test "does NOT report when exactly 3 quotes are found" do
    create_snippet(~s(f\\"b\\"\\"))
      |> to_source_file
      |> refute_issues(@described_check)
  end

  test "reports for more than 3 quotes" do
    create_snippet(~s(f\\"\\"b\\"\\"))
      |> to_source_file
      |> assert_issue(@described_check)
  end

  test "reports for more than :maximum_allowed_quotes quotes" do
    create_snippet(~s(f\\"\\"b\\"\\\"\\"\\"))
      |> to_source_file
      |> assert_issue(@described_check, maximum_allowed_quotes: 5)
  end

  test "does NOT report when less than :maximum_allowed_quotes quotes are found" do
    create_snippet(~s(f\\"\\"\\"\\"))
      |> to_source_file
      |> refute_issues(@described_check, maximum_allowed_quotes: 5)
  end

  test "does NOT report when exactly :maximum_allowed_quotes quotes are found" do
    create_snippet(~s(f\\"\\"\\"\\"))
    |> to_source_file
    |> refute_issues(@described_check, maximum_allowed_quotes: 4)
  end

  test "does NOT report for quotes in sigil_s" do
    create_sigil_snippet(~s(f\\"\\"b\\"\\"))
      |> to_source_file
      |> refute_issues(@described_check)
  end

  test "does NOT report for quotes in sigil_r" do
    create_sigil_snippet(~s(f\\"\\"b\\"\\"), "r")
     |> to_source_file
     |> refute_issues(@described_check)
  end
end
