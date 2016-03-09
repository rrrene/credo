defmodule Credo.Check.LintAttributeTest do
  use Credo.TestHelper

  alias Credo.Check.LintAttribute
  alias Credo.Issue

  # Asserts that a given `source` produces the `expected` value.
  defp assert_value(source, expected) do
    input = source |> Code.string_to_quoted!
    lint_attribute = LintAttribute.from_ast(input)
    assert expected == lint_attribute.value, "Expected #{inspect(expected)}, got #{inspect(lint_attribute.value)}"
  end


  test "it should return " do
    assert_value "@lint false",
                        false
  end

  test "it should work for a tuple" do
    assert_value "@lint {Credo.Check.Design.AliasUsage, false}",
                        [{Credo.Check.Design.AliasUsage, false}]
  end

  test "it should work for a Regex" do
    assert_value "@lint {~r/Refactor/, false}",
                        [{~r/Refactor/, false}]
  end

  test "it should work for a Regex ~R" do
    assert_value "@lint {~R/Refactor/, false}",
                        [{~R/Refactor/, false}]
  end

  test "it should work for a list of tuples" do
    assert_value "@lint [{Credo.Check.Design.AliasUsage, false}]",
                        [{Credo.Check.Design.AliasUsage, false}]
  end

  test "it should work for a list of Regexes" do
    assert_value "@lint [{~r/Refactor/, false}]",
                        [{~r/Refactor/, false}]
  end


  test "it should work for a tuple, followed by a custom params list" do
    assert_value "@lint {Credo.Check.Design.AliasUsage, a: 1, b: 2}",
                        [{Credo.Check.Design.AliasUsage, a: 1, b: 2}]
  end

  test "it should work for a Regex, followed by a custom params list" do
    assert_value "@lint {~r/Refactor/, a: 1, b: 2}",
                        [{~r/Refactor/, a: 1, b: 2}]
  end

  test "it should work for a Regex ~R, followed by a custom params list" do
    assert_value "@lint {~R/Refactor/, a: 1, b: 2}",
                        [{~R/Refactor/, a: 1, b: 2}]
  end

  test "it should work for a list of tuples, followed by a custom params list" do
    assert_value "@lint [{Credo.Check.Design.AliasUsage, a: 1, b: 2}]",
                        [{Credo.Check.Design.AliasUsage, a: 1, b: 2}]
  end

  test "it should work for a list of Regexes, followed by a custom params list" do
    assert_value "@lint [{~r/Refactor/, a: 1, b: 2}]",
                        [{~r/Refactor/, a: 1, b: 2}]
  end


  test "it should return true for @lint false with same scope" do
    issue = %Issue{check: Credo.Check.Refactor.ABCSize, scope: "MyScope.fun"}
    lint_attribute = %LintAttribute{value: false, scope: "MyScope.fun"}
    assert LintAttribute.ignores_issue?(lint_attribute, issue)
  end

  test "it should return false for @lint false with other scope" do
    issue = %Issue{check: Credo.Check.Refactor.ABCSize, scope: "MyScope.fun"}
    lint_attribute = %LintAttribute{value: false, scope: "MyScope.fun2"}
    refute LintAttribute.ignores_issue?(lint_attribute, issue)
  end


  test "it should return true for @lint [{check, false}] with same scope" do
    issue = %Issue{check: Credo.Check.Refactor.ABCSize, scope: "MyScope.fun"}
    lint_attribute = %LintAttribute{value: [{Credo.Check.Refactor.ABCSize, false}], scope: "MyScope.fun"}
    assert LintAttribute.ignores_issue?(lint_attribute, issue)
  end

  test "it should return false for @lint [{check, false}] with other scope" do
    issue = %Issue{check: Credo.Check.Refactor.ABCSize, scope: "MyScope.fun"}
    lint_attribute =
      %LintAttribute{
        value: [{Credo.Check.Refactor.ABCSize, false}],
        scope: "MyScope.other_fun"
      }
    refute LintAttribute.ignores_issue?(lint_attribute, issue)
  end

  test "it should return false for @lint [{check, false}] with other check" do
    issue = %Issue{check: Credo.Check.Refactor.ABCSize, scope: "MyScope.fun"}
    lint_attribute =
      %LintAttribute{
        value: [{Credo.Check.Refactor.CyclomaticComplexity, false}],
        scope: "MyScope.fun"
      }
    refute LintAttribute.ignores_issue?(lint_attribute, issue)
  end


  test "it should return true for @lint [{~r//, false}] with same scope" do
    issue = %Issue{check: Credo.Check.Refactor.ABCSize, scope: "MyScope.fun"}
    lint_attribute = %LintAttribute{value: [{~r/Refactor/, false}], scope: "MyScope.fun"}
    assert LintAttribute.ignores_issue?(lint_attribute, issue)
  end

  test "it should return false for @lint [{~r//, false}] with other scope" do
    issue = %Issue{check: Credo.Check.Refactor.ABCSize, scope: "MyScope.fun"}
    lint_attribute =
      %LintAttribute{
        value: [{~r/Refactor/, false}],
        scope: "MyScope.other_fun"
      }
    refute LintAttribute.ignores_issue?(lint_attribute, issue)
  end

  test "it should return false for @lint [{~r//, false}] with other check" do
    issue = %Issue{check: Credo.Check.Refactor.ABCSize, scope: "MyScope.fun"}
    lint_attribute =
      %LintAttribute{
        value: [{~r/Readability/, false}],
        scope: "MyScope.fun"
      }
    refute LintAttribute.ignores_issue?(lint_attribute, issue)
  end

end
