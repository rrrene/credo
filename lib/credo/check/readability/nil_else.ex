defmodule Credo.Check.Readability.NilElse do
  @moduledoc false

  @checkdoc """
  Do not use `nil` as a return value of `else` in `if` or `unless`.
  The function returns `nil` by default, so adding an else block
  just adds unnecessary code.

  The code in this example ...
      if x > 5 do
        x * 2
      else
        nil
      end
  ... should be refactored to look like this:
      if x > 5 do
        x * 2
      end
  """
  @explanation [check: @checkdoc]

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse(
         {conditional, meta, [_, [{:do, _} | [{:else, nil} | _]]]} = ast,
         issues,
         issue_meta
       )
       when conditional in [:if, :unless] do
    {ast, [issue_for(issue_meta, meta[:line]) | issues]}
  end

  defp traverse(ast, issues, _) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "Do not use `nil` as the result of `else` in `if` or `unless`",
      trigger: "no_nil_else",
      line_no: line_no
    )
  end
end
