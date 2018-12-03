defmodule Credo.CLI.Output.Formatter.ReportCard do
  @moduledoc false

  def categorize_module(issue, module_map) do
    Map.update(
      module_map,
      issue.filename,
      [issue],
      fn v ->
        [issue | v]
      end
    )
  end

  def grade(adjusted_score) do
    case adjusted_score do
      adjusted_score when adjusted_score < 16 -> "A"
      adjusted_score when adjusted_score < 61 -> "B"
      adjusted_score when adjusted_score < 121 -> "C"
      adjusted_score when adjusted_score < 241 -> "D"
      adjusted_score when adjusted_score < 481 -> "E"
      _ -> "F"
    end
  end

  def score_issues(_, issues) do
    issue_count = Enum.count(issues)

    total =
      Enum.reduce(issues, 0.0, fn issue, acc ->
        acc + issue_score(issue)
      end)

    {issue_count, Float.ceil(total, 2)}
  end

  def format_remediation_time(val) do
    case val do
      val when val < 2 -> "1 minute"
      val when val < 46 -> Integer.to_string(round(val)) <> " minutes"
      val when val < 70 and val > 45 -> "1 hour"
      _ -> format_remediation_greater_than_one_hour(val)
    end
  end

  defp format_remediation_greater_than_one_hour(val) do
    case val do
      val when val < 504 and val > 419 -> "1 day"
      val when val > 503 -> single_decimal_string_from(val / 60.0 / 8.0) <> " days"
      val when val < 130 and val > 69 -> "2 hours"
      _ -> single_decimal_string_from(val / 60.0) <> " hours"
    end
  end

  @issue_remediation %{
    Credo.Check.Consistency.SpaceInParentheses => 1,
    Credo.Check.Consistency.TabsOrSpaces => 2,
    Credo.Check.Design.AliasUsage => 3,
    Credo.Check.Design.DuplicatedCode => 15,
    Credo.Check.Readability.AliasOrder => 1,
    Credo.Check.Readability.MaxLineLength => 1,
    Credo.Check.Readability.ModuleDoc => 10,
    Credo.Check.Readability.ModuleNames => 10,
    Credo.Check.Readability.RedundantBlankLines => 1,
    Credo.Check.Readability.SpaceAfterCommas => 1,
    Credo.Check.Readability.TrailingBlankLine => 1,
    Credo.Check.Readability.TrailingWhiteSpace => 1,
    Credo.Check.Refactor.ABCSize => 15,
    Credo.Check.Refactor.CyclomaticComplexity => 15,
    Credo.Check.Refactor.Nesting => 15,
    Credo.Check.Warning.NameRedeclarationByFn => 10,
    Credo.Check.Warning.OperationOnSameValues => 10,
    Credo.Check.Warning.BoolOperationOnSameValues => 10,
    Credo.Check.Warning.UnusedEnumOperation => 5,
    Credo.Check.Warning.UnusedKeywordOperation => 5,
    Credo.Check.Warning.UnusedListOperation => 5,
    Credo.Check.Warning.UnusedStringOperation => 5,
    Credo.Check.Warning.UnusedTupleOperation => 5,
    Credo.Check.Warning.OperationWithConstantResult => 5,
    Credo.Check.Readability.Specs => 5
  }

  alias Credo.Issue

  defp issue_score(%Issue{check: Credo.Check.Refactor.CyclomaticComplexity, severity: sev}) do
    15 * sev
  end

  defp issue_score(%Issue{check: Credo.Check.Warning.ExCoverallsUncovered, severity: sev}) do
    10 * sev
  end

  defp issue_score(issue) do
    @issue_remediation[issue.check] || 5
  end

  defp single_decimal_string_from(val) do
    :erlang.float_to_binary(val, decimals: 1)
  end
end
