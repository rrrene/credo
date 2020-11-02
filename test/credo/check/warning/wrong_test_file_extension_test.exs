defmodule Credo.Check.Warning.WrongTestFileExtensionTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.WrongTestFileExtension

  #
  # cases NOT raising issues
  #

  test "it should NOT report test files that end with _test.exs" do
    """
    defmodule Credo.Check.Warning.WrongTestFileExtensionTest do
      test "some test" do
        assert true
      end
    end
    """
    |> to_source_file("test/credo/check/warning/test_exs_test.exs")
    |> run_check(@described_check)
    |> refute_issues()
  end

  test "it should NOT report excluded files" do
    """
    defmodule Credo.Check.Warning.WrongTestFileExtensionTest do
      test "some test" do
        assert true
      end
    end
    """
    |> to_source_file("excluded_pattern/some_test.ex")
    |> run_check(@described_check, excluded_paths: ["excluded_pattern/"])
    |> refute_issues()
  end

  #
  # cases raising issues
  #

  test "it should report test files that end with _test.ex" do
    """
    defmodule Credo.Check.Warning.WrongTestFileExtensionTest do
      test "some test" do
        assert true
      end
    end
    """
    |> to_source_file("test/credo/check/warning/test_exs_test.ex")
    |> run_check(@described_check)
    |> assert_issue()
  end
end
