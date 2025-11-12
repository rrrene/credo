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
    ctx = Context.build(source_file, params, __MODULE__)

    result =
      source_file
      |> Credo.Code.clean_charlists_strings_and_sigils()
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.map(&transform_line/1)
      |> check_lines(ctx)

    result.issues
  end

  defp transform_line({line, line_number}) do
    tag_skip_regex = ~r/^\s*\@tag :skip\s*$/
    comment_regex = ~r/^\s*\#.*$/

    cond do
      line =~ tag_skip_regex -> {:tag_skip, line_number}
      line =~ comment_regex -> {:comment, line_number}
      true -> {line, line_number}
    end
  end

  defp check_lines([{:tag_skip, line_number} | rest], ctx) do
    check_lines(rest, put_issue(ctx, issue_for(ctx, line_number)))
  end

  defp check_lines([{:comment, _}, {:tag_skip, _} | rest], ctx) do
    check_lines(rest, ctx)
  end

  defp check_lines([_hd | tl], ctx), do: check_lines(tl, ctx)
  defp check_lines([], ctx), do: ctx

  defp issue_for(ctx, line_no) do
    format_issue(
      ctx,
      message: "Tests tagged to be skipped should have a comment preceding the `@tag :skip`.",
      trigger: "@tag :skip",
      line_no: line_no
    )
  end
end
