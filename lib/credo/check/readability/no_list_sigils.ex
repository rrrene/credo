defmodule Credo.Check.Readability.NoListSigils do
  use Credo.Check,
    param_defaults: [],
    explanations: [
      check: ~S"""
      Code is read more times than it is written and although the ~w and ~W sigils 
      allow for brevity in code, explicit list definitions have the benefit that they are 
      both relatively brief and completely unambiguous.

      # preferred

          ["foo", "bar", "baz"]
          [:"例（括弧）+追加", :別言葉]
          [~S({"key":"value"}), ~S({"key2":"value2"})]

      # NOT preferred

          ~w'foo bar baz'
          ~w/例（括弧）+追加 別言葉/a
          ~W({"key":"value"} {"key2":"value2"})

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
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
