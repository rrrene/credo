defmodule Credo.Check.Refactor.AppendSingleItem do
  use Credo.Check,
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
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # [a] ++ b is OK
  # TODO: consider for experimental check front-loader (ast)
  defp traverse({:++, _, [[_], _]} = ast, issues, _issue_meta) do
    {ast, issues}
  end

  # a ++ [b] is not
  defp traverse({:++, meta, [_, [_]]} = ast, issues, issue_meta) do
    {ast, [issue_for(issue_meta, meta[:line], :++) | issues]}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Appending a single item to a list is inefficient, use [head | tail]
                notation (and Enum.reverse/1 when order matters)",
      trigger: trigger,
      line_no: line_no
    )
  end
end
