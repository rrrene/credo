defmodule Credo.Check.Design.SkipTestWithoutComment do
  use Credo.Check,
    base_priority: :normal,
    explanations: [
      check: """
      Skipped tests should have a comment documenting why the test is skipped. Tests are often skipped using `@tag :skip` when some issue
      arises that renders the test temporarily broken or unable to run. This temporary skip often becomes permanent because the reason
      for the test being skipped is not documented. A comment should exist on the line prior to the skip tag describing why the test is
      skipped, making future removal of the tag more likely. For example:

          # Our credentials expired, working on getting new ones
          @tag :skip
          test "vendor api returns data" do
            ...

      """
    ]

  alias Credo.Code.Heredocs

  @doc false
  @impl true
  def run(%SourceFile{filename: filename} = source_file, params) do
    if is_nil(filename) or !String.ends_with?(filename, "_test.exs") do
      []
    else
      issue_meta = IssueMeta.for(source_file, params)

      source_file
      |> Heredocs.replace_with_spaces()
      |> String.split("\n")
      |> Enum.with_index(1)
      |> Enum.map(&transform_line/1)
      |> check_lines([], issue_meta)
    end
  end

  @tag_skip_regex ~r/^\s*\@tag :skip($|[ \t]+.*$)/
  @comment_regex ~r/^\s*\#.*$/

  def transform_line({line, line_number}) do
    cond do
      line =~ @tag_skip_regex -> {:tag_skip, line_number}
      line =~ @comment_regex -> {:comment, line_number}
      true -> {nil, line_number}
    end
  end

  def check_lines([{:tag_skip, line_number} | rest], issues, issue_meta) do
    check_lines(rest, [issue_for(issue_meta, line_number) | issues], issue_meta)
  end

  def check_lines([{:comment, _}, {:tag_skip, _} | rest], issues, issue_meta) do
    check_lines(rest, issues, issue_meta)
  end

  def check_lines([_hd | tl], issues, issue_meta), do: check_lines(tl, issues, issue_meta)
  def check_lines([], issues, _issue_meta), do: issues

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "@tag :skip should have a comment preceding it explaining the :skip",
      trigger: "@tag :skip",
      line_no: line_no
    )
  end
end
