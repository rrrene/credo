defmodule Credo.Check.Readability.SinglePipe do
  use Credo.Check,
    base_priority: :high,
    tags: [:controversial],
    explanations: [
      check: """
      Pipes (`|>`) should only be used when piping data through multiple calls.

      So while this is fine:

          list
          |> Enum.take(5)
          |> Enum.shuffle
          |> evaluate()

      The code in this example ...

          list
          |> evaluate()

      ... should be refactored to look like this:

          evaluate(list)

      Using a single |> to invoke functions makes the code harder to read. Instead,
      write a function call when a pipeline is only one function long.

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
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

  # TODO: consider for experimental check front-loader (ast)
  defp traverse({:|>, _, [{:|>, _, _} | _]} = ast, {_, issues}, _) do
    {ast, {false, issues}}
  end

  defp traverse({:|>, meta, _} = ast, {true, issues}, issue_meta) do
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
      message: "Use a function call when a pipeline is only one function long",
      trigger: trigger,
      line_no: line_no
    )
  end
end
