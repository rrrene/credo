defmodule Credo.Check.Readability.BlockPipe do
  use Credo.Check,
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

      Like all `Readability` issues, this one is not a technical concern, but you can improve the odds of others reading
      and understanding the intent of your code by making it easier to follow.
      """,
      params: [
        exclude: "Do not raise an issue for these macros and functions."
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    excluded_functions = Params.get(params, :exclude, __MODULE__)

    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(
      source_file,
      &traverse(&1, &2, excluded_functions, issue_meta)
    )
  end

  defp traverse(
         {:|>, meta, [_, {function, _, [[{:do, _} | _]]}]} = ast,
         issues,
         excluded_functions,
         issue_meta
       ) do
    if Enum.member?(excluded_functions, function) do
      {ast, issues}
    else
      {nil, issues ++ [issue_for(issue_meta, meta[:line], "|>")]}
    end
  end

  defp traverse(ast, issues, _excluded_functions, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Use a variable or create a new function instead of piping to a block",
      trigger: trigger,
      line_no: line_no
    )
  end
end
