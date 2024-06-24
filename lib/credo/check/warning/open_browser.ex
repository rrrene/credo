defmodule Credo.Check.Warning.OpenBrowser do
  @moduledoc """
  Check for tests containing open_browser calls.
  """

  use Credo.Check,
    base_priority: :high,
    category: :consistency,
    param_defaults: [
      files: %{included: ["test/**/*_test.exs", "apps/**/test/**/*_test.exs"]}
    ],
    explanations: [
      check: """
      Remove calls to open_browser. These support local development and should not be committed.
      """
    ]

  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # This matches on the AST structure of a open_browser function call
  defp traverse(
         {:open_browser, meta, _} = ast,
         issues,
         issue_meta
       ) do
    {ast, issues ++ [issue_for("open_browser", meta[:line], issue_meta)]}
  end

  # For all AST nodes not matching the pattern above, we simply do nothing:
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(trigger, line_no, issue_meta) do
    format_issue(
      issue_meta,
      message: "There should be no calls to open_browser.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
