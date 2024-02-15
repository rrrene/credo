defmodule Credo.Check.Design.SkipTestWithoutComment do
  use Credo.Check,
    id: "EX2003",
    base_priority: :normal,
    param_defaults: [
      files: %{included: ["test/**/*_test.exs"]}
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
    comments = SourceFile.comments(source_file)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, comments, issue_meta))
  end

  defp traverse({:@, meta, [{:tag, _, [:skip]}]} = ast, issues, comments, issue_meta) do
    with line_no <- meta[:line] - 1,
         Enum.find(comments, fn
           %{line: ^line_no} -> true
           _ -> false
         end) do
      {ast, [issue_for(issue_meta, meta[:line])] ++ issues}
    else
      _ -> {ast, issues}
    end
  end

  defp traverse(ast, issues, _comments, _issue_meta), do: {ast, issues}

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "Tests tagged to be skipped should have a comment preceding the `@tag :skip`.",
      trigger: "@tag :skip",
      line_no: line_no
    )
  end
end
