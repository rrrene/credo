defmodule Credo.Check.Refactor.AppendSingleItem do
  use Credo.Check,
    id: "EX4002",
    base_priority: :low,
    tags: [:controversial],
    explanations: [
      check: """
      When building up large lists, it is faster to prepend than
      append. Therefore: It is sometimes best to prepend to the list
      during iteration and call Enum.reverse/1 at the end, as it is quite
      fast.

      Example:

          list = list_so_far ++ [new_item]

          # refactoring it like this can make the code faster:

          list = [new_item] ++ list_so_far
          # ...
          Enum.reverse(list)

      """
    ],
    managed_traversal: :ast

  # [a] ++ b is OK
  def handle_walk({:++, _, [[_], _]} = ast, ctx) do
    {ast, ctx}
  end

  # a ++ [b] is not
  def handle_walk({:++, meta, [_, [_]]} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  def handle_walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta) do
    format_issue(
      ctx,
      message:
        "Appending a single item to a list is inefficient, use `[head | tail]` notation (and `Enum.reverse/1` when order matters).",
      trigger: "++",
      line_no: meta[:line]
    )
  end
end
