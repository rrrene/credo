defmodule Credo.Check.Design.SkipTestWithoutCommentTest do
  use Credo.Test.Case

  @described_check Credo.Check.Design.SkipTestWithoutComment

  test "it should NOT report when comment preceeds the tag" do
    """
    defmodule CredoSampleModuleTest do
      alias ExUnit.Case

      # Some comment
      @tag :skip
      test "foo" do
        :ok
      end

    end
    """
    |> to_source_file("foo_test.exs")
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report non-test files" do
    """
    defmodule CredoSampleModuleTest do
      alias ExUnit.Case

      @tag :skip
      test "foo" do
        :ok
      end

    end
    """
    |> to_source_file("foo.ex")
    |> run_check(@described_check)
    |> refute_issues()
  end

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
