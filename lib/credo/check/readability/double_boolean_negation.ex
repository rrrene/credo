defmodule Credo.Check.Readability.DoubleBooleanNegation do
  @moduledoc """
  Having double negations in your code reduces readability.

      # Double boolean negation:
      !!var

      # or:
      not not var

  Using `!!` will be inconsistent for some values like `nil`.
  Try to be more explicit for handling boolean values.
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :low

  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # Checking for `!!`
  defp traverse({:!, [line: line_no], [{:!, _, ast}]}, issues, issue_meta) do
    issue = format_issue issue_meta,
      message: "Double boolean negation found.",
      trigger: "!!",
      line_no: line_no

    {ast, [issue | issues]}
  end

  # Checking for `not not`
  defp traverse({:not, [line: line_no], [{:not, _, ast}]}, issues, issue_meta) do
    issue = format_issue issue_meta,
      message: "Double boolean negation found.",
      trigger: "not not",
      line_no: line_no

    {ast, [issue | issues]}
  end

  defp traverse(ast, issues, issue_meta) do
    {ast, issues}
  end
end
