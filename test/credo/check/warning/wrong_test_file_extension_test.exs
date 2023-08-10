defmodule Credo.Check.Warning.WrongTestFileExtensionTest do
  use Credo.Test.Case

  @described_check Credo.Check.Warning.WrongTestFileExtension

  alias Credo.Issue

  #
  # cases raising issues
  #

  test "reports test files that end with _test.ex" do
    assert_issue_for_soruce_file("test/foo_test.ex")
    assert_issue_for_soruce_file("test/nested/directory/foo_test.ex")
  end

  test "reports test files that end with the .exs extension but without _test suffix" do
    assert_issue_for_soruce_file("test/foo.exs")
    assert_issue_for_soruce_file("test/nested/directory/foo.exs")
  end

  #
  # cases NOT raising issues
  #

  test "does NOT report test files that end with _test.exs" do
    refute_issue_for_soruce_file("test/credo/check/warning/test_exs_test.exs")
  end

  test "does NOT report anything outside the test directory" do
    for path <- ["priv/foo.exs", "mix/tasks/bar.exs", "lib/app/baz_test.ex"] do
      refute_issue_for_soruce_file(path)
    end
  end

  test "does NOT report excluded files" do
    # Ignored by default
    refute_issue_for_soruce_file("test/support/mocks.exs")
    refute_issue_for_soruce_file("test/test_helper.exs")

    params = [
      excluded_paths: [
        "test/support_modules",
        ~r/^test\/my_test_helper.exs$/
      ]
    ]

    refute_issue_for_soruce_file("test/support_modules/foo_test.ex", params)
    refute_issue_for_soruce_file("test/my_test_helper.exs", params)
    assert_issue_for_soruce_file("test/my_test_helper.exs/foo_test.ex", params)
  end

  defp assert_issue_for_soruce_file(filename, params \\ []) do
    filename
    |> run_credo_check(params)
    |> assert_issue(
      &assert %Issue{filename: ^filename, message: "Test files should end with `_test.exs`"} = &1
    )
  end

  defp refute_issue_for_soruce_file(filename, params \\ []) do
    filename
    |> run_credo_check(params)
    |> refute_issues()
  end

  defp run_credo_check(filename, params) do
    """
    defmodule MyAppTest do
    end
    """
    |> to_source_file(filename)
    |> run_check(@described_check, params)
  end
end
