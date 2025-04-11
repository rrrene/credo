defmodule Credo.Check.Design.SkipTestWithoutComment do
  use Credo.Check,
    id: "EX2003",
    base_priority: :normal,
    param_defaults: [
      files: %{included: ["test/**/*_test.exs", "apps/**/test/**/*_test.exs"]}
    ],
    explanations: [
      check: """
      Skipped tests should have a comment documenting why the test is skipped.

      Tests are often skipped using `@tag :skip` when some issue arises that renders
      the test temporarily broken or unable to run. This temporary skip often becomes
      a permanent one because the reason for the test being skipped is not documented.

      A comment should exist on the line prior to the skip tag describing why the test is
      skipped.

      Example:

          # john: skipping this since our credentials expired, working on getting new ones
          @tag :skip
          test "vendor api returns data" do
            # ...
          end

      While the pure existence of a comment does not change anything per se, a thoughtful
      comment can improve the odds for future iteration on the issue.
      """
    ]

  @doc false
  @impl true
  def run(source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    {ast, comments} = SourceFile.ast_with_comments(source_file)

    Credo.Code.prewalk(ast, &traverse(&1, &2, issue_meta, comments))
  end

  defp traverse({:@, meta, [{:tag, _, [:skip]} | _]} = ast, issues, issue_meta, comments) do
    line_no = meta[:line] - 1

    found_comment? = Enum.any?(comments, fn %{line: line_no2} -> line_no2 == line_no end)

    if found_comment? do
      {ast, issues}
    else
      issue = issue_for(issue_meta, line_no)
      {ast, [issue | issues]}
    end
  end

  defp traverse(ast, issues, _issue_meta, _comments) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "Tests tagged to be skipped should have a comment preceding the `@tag :skip`.",
      trigger: "@tag :skip",
      line_no: line_no
    )
  end
end
