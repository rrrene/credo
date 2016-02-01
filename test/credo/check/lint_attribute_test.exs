defmodule Credo.Check.LintAttributeTest do
  use Credo.TestHelper

  alias Credo.Check.LintAttribute
  alias Credo.Issue


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
