defmodule Credo.Check.Readability.ExprPipe do
  use Credo.Check,
    base_priority: :high,
    tags: [:controversial],
    explanations: [
      check: """
      Pipes (`|>`) should not be used with case, if, or unless expressions.

      The code in this example ...

          list
          |> Enum.take(5)
          |> Enum.sort()
          |> case do 
            [[_h|_t]|_] -> true
            _ -> false
          end

      ... should be refactored to look like this:

          maybe_nested_lists = list
                               |> Enum.take(5)
                               |> Enum.sort()

          case maybe_nested_lists do 
            [[_h|_t]|_] = true
            _->  false
          end


      ... or create a new function

          list
          |> Enum.take(5)
          |> Enum.sort()
          |> contains_nested_list?()


      Piping to expressions is harder to read because it may obscure intention, increase cognitive load on the 
      reader, and suprising to the reader per not following basic syntax principles set forth by all other 
      expressions. Instead, prefer introducing variables to your code or new functions when it may be a sign that 
      your function is getting too big and/or has too many concerns. 

      Like all `Readability` issues, this one is not a technical concern, but you can improve the odds of others reading
      and understanding the intent of your code by making it easier to follow. 
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    {_continue, issues} =
      Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta), {true, []})

    issues
  end

  defp traverse({:|>, meta, [_, {expr, _, _}]} = ast, {true, issues}, issue_meta)
       when expr in [:case, :if, :unless] do
    {
      ast,
      {false, issues ++ [issue_for(issue_meta, meta[:line], "|>")]}
    }
  end

  defp traverse(ast, {_, issues}, _issue_meta) do
    {ast, {true, issues}}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Use a variable or create a new function instead of piping to a case, if, or unless expression",
      trigger: trigger,
      line_no: line_no
    )
  end
end
