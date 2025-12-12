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
    {ast, comments} = SourceFile.ast_with_comments(source_file)
    ctx = Context.build(source_file, params, __MODULE__, %{comments: comments})

    result = Credo.Code.prewalk(ast, &traverse/2, ctx)
    result.issues
  end

  defp traverse({:@, meta, [{:tag, _, [:skip]} | _]} = ast, ctx) do
    line_no = meta[:line] - 1

    found_comment? = Enum.any?(ctx.comments, fn %{line: line_no2} -> line_no2 == line_no end)

    if found_comment? do
      {ast, ctx}
    else
      {ast, put_issue(ctx, issue_for(ctx, meta[:line]))}
    end
  end

  defp traverse(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, line_no) do
    format_issue(
      ctx,
      message: "Tests tagged to be skipped should have a comment preceding the `@tag :skip`.",
      trigger: "@tag :skip",
      line_no: line_no
    )
  end
end
