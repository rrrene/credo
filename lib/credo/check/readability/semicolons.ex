defmodule Credo.Check.Readability.Semicolons do
  @moduledoc """
  Don't use ; to separate statements and expressions.
  Statements and expressions should be separated by lines.

  Like all `Readability` issues, this one is not a technical concern.
  But you can improve the odds of others reading and liking your code by making
  it easier to follow.
  """

  @explanation [
    check: @moduledoc
  ]

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.to_tokens
    |> collect_issues([], issue_meta)
  end

  defp collect_issues([], acc, _issue_meta), do: acc
  defp collect_issues([{:";", {line_no, column1, _}} | rest], acc, issue_meta) do
    acc = [issue_for(issue_meta, line_no, column1) | acc]
    collect_issues(rest, acc, issue_meta)
  end
  defp collect_issues([_ | rest], acc, issue_meta), do: collect_issues(rest, acc, issue_meta)

  def issue_for(issue_meta, line_no, column) do
    format_issue issue_meta,
      message: "Don't use ; to separate statements and expressions",
      line_no: line_no,
      column: column,
      trigger: ";"
  end
end
