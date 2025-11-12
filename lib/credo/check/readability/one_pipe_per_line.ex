defmodule Credo.Check.Readability.OnePipePerLine do
  use Credo.Check,
    id: "EX3035",
    category: :readability,
    explanations: [
      check: """
      Don't use multiple pipes (|>) in the same line.
      Each function in the pipe should be in it's own line.

          # preferred

          foo
          |> bar()
          |> baz()

          # NOT preferred

          foo |> bar() |> baz()

      The code in this example ...

          1 |> Integer.to_string() |> String.to_integer()

      ... should be refactored to look like this:

          1
          |> Integer.to_string()
          |> String.to_integer()

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    ctx = Context.build(source_file, params, __MODULE__, %{issue_candidates: []})
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)

    result.issue_candidates
    |> Enum.uniq()
    |> Enum.map(&issue_for(ctx, &1))
  end

  defp walk({:|>, meta, [{:|>, meta2, _} | _]} = ast, ctx) do
    if meta[:line] == meta2[:line] do
      {ast, push(ctx, :issue_candidates, meta)}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta) do
    format_issue(
      ctx,
      message: "Avoid using multiple pipes (`|>`) on the same line.",
      trigger: "|>",
      line_no: meta[:line]
    )
  end
end
