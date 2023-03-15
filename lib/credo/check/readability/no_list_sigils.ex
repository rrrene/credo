defmodule Credo.Check.Readability.NoListSigils do
  @moduledoc """
  A check to suggest explicit lists over the ~w and ~W sigls.
  """
  use Credo.Check,
    param_defaults: [],
    explanations: [
      check: ~S"""
      Although the ~w and ~W sigils allow for brevity when writing code, code is
      read many more times than it is written. List definitions are both relatively
      brief and completely unambiguous; consider defining lists explicitly rather than
      via the sigil.

      Instead of

          ~w'foo bar baz'
          ~w/例（括弧）+追加 別言葉/a
          ~W({"key":"value"} {"key2":"value2"})

      Prefer:

          ["foo", "bar", "baz"]
          [:"例（括弧）+追加", :別言葉]
          [~S({"key":"value"}), ~S({"key2":"value2"})]
      """,
      params: []
    ]

  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:sigil_w, context, _args} = ast, issues, issue_meta) do
    issue =
      format_issue(
        issue_meta,
        message: ~S{Avoid ~w sigil: ~w(foo bar), prefer explicit lists: ["foo", "bar"]},
        trigger: :sigil_w,
        line_no: context[:line]
      )

    {ast, [issue | issues]}
  end

  defp traverse({:sigil_W, context, _args} = ast, issues, issue_meta) do
    issue =
      format_issue(
        issue_meta,
        message:
          ~S<Avoid ~W sigil: ~W({"key":"value"}), prefer explicit lists: [~S({"key":"value"})]>,
        trigger: :sigil_W,
        line_no: context[:line]
      )

    {ast, [issue | issues]}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end
end
