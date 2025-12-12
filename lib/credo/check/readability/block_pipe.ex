defmodule Credo.Check.Readability.BlockPipe do
  use Credo.Check,
    id: "EX3003",
    tags: [:controversial],
    param_defaults: [
      exclude: []
    ],
    explanations: [
      check: """
      Pipes (`|>`) should not be used with blocks.

      The code in this example ...

          list
          |> Enum.take(5)
          |> Enum.sort()
          |> case do
            [[_h | _t] | _] -> true
            _ -> false
          end

      ... should be refactored to look like this:

          maybe_nested_lists =
            list
            |> Enum.take(5)
            |> Enum.sort()

          case maybe_nested_lists do
            [[_h | _t] | _] -> true
            _ -> false
          end

      ... or create a new function:

          list
          |> Enum.take(5)
          |> Enum.sort()
          |> contains_nested_list?()

      Piping to blocks may be harder to read because it can be said that it obscures intentions
      and increases cognitive load on the reader. Instead, prefer introducing variables to your code or
      new functions when it may be a sign that your function is getting too complicated and/or has too many concerns.

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """,
      params: [
        exclude: "Do not raise an issue for these macros and functions."
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:|>, meta, [_, {function, _, [[{:do, _} | _]]}]} = ast, ctx) do
    if Enum.member?(ctx.params.exclude, function) do
      {ast, ctx}
    else
      {nil, put_issue(ctx, issue_for(ctx, meta))}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta) do
    format_issue(
      ctx,
      message: "Use a variable or create a new function instead of piping to a block.",
      trigger: "|>",
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
