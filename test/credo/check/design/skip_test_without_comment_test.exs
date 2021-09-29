defmodule Credo.Check.Design.SkipTestWithoutCommentTest do
  use Credo.Test.Case

  @described_check Credo.Check.Design.SkipTestWithoutComment

  test "it should NOT report when comment precedes the tag" do
    """
    defmodule CredoSampleModuleTest do
      alias ExUnit.Case

      # Happy case: Some comment
      @tag :skip
      test "foo" do
        :ok
      end

      # Some comment
      @tag :skip
      # another comment, shouldn't matter
      test "foo2" do
        :ok
      end
    end
    """
    |> to_source_file("foo_test.exs")
    |> run_check(@described_check)
    |> refute_issues()
  end

  @tag :skip
  test "it should report a violation" do
    """
    defmodule CredoSampleModuleTest do
      alias ExUnit.Case

      @tag :skip
      test "foo" do
        :ok
      end
    end
    """
    |> to_source_file("foo_test.exs")
    |> run_check(@described_check)
    |> assert_issue()
  end
end
