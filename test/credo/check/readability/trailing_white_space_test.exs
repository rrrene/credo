defmodule Credo.Check.Readability.TrailingWhiteSpaceTest do
  use Credo.Test.Case

  @described_check Credo.Check.Readability.TrailingWhiteSpace

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

  test "it should NOT report trailing whitespace inside heredocs" do
    """
    defmodule CredoSampleModule do
      @doc '''
      Foo++
      Bar
      '''
    end
    """
    |> String.replace("++", "  ")
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report \r line endings" do
    """
    defmodule CredoSampleModule do\r
    end\r
    """
    |> to_source_file
    |> run_check(@described_check)
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report a violation" do
    "defmodule CredoSampleModule do\n@test true   \nend"
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issue(fn issue ->
      assert 11 == issue.column
      assert "   " == issue.trigger
    end)
  end

  test "it should report multiple violations" do
    "defmodule CredoSampleModule do   \n@test true   \nend"
    |> to_source_file
    |> run_check(@described_check)
    |> assert_issues()
  end

  test "it should report trailing whitespace inside heredocs if :ignore_strings is false" do
    """
    defmodule CredoSampleModule do
      @doc '''
      Foo++
      Bar
      '''
    end
    """
    |> String.replace("++", "  ")
    |> to_source_file
    |> run_check(@described_check, ignore_strings: false)
    |> assert_issue()
  end
end
