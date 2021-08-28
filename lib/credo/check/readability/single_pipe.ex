defmodule Credo.Check.Readability.SinglePipe do
  use Credo.Check,
    base_priority: :high,
    tags: [:controversial],
    param_defaults: [allow_0_arity_functions: false],
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
      """,
      params: [
        allow_0_arity_functions: "Allow 0-arity functions"
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    allow_0_arity_functions = Params.get(params, :allow_0_arity_functions, __MODULE__)

    {_continue, issues} =
      Credo.Code.prewalk(
        source_file,
        &traverse(&1, &2, issue_meta, allow_0_arity_functions),
        {true, []}
      )

    issues
  end

  defp traverse({:|>, _, [{:|>, _, _} | _]} = ast, {_, issues}, _, _) do
    {ast, {false, issues}}
  end

  defp traverse({:|>, meta, _} = ast, {true, issues}, issue_meta, false) do
    {
      ast,
      {false, issues ++ [issue_for(issue_meta, meta[:line], "|>")]}
    }
  end

  defp traverse({:|>, _, [{{:., _, _}, _, []}, _]} = ast, {true, issues}, _, true) do
    {ast, {false, issues}}
  end

  defp traverse({:|>, _, [{fun, _, []}, _]} = ast, {true, issues}, _, true) when is_atom(fun) do
    {ast, {false, issues}}
  end

  defp traverse({:|>, meta, _} = ast, {true, issues}, issue_meta, true) do
    {
      ast,
      {false, issues ++ [issue_for(issue_meta, meta[:line], "|>")]}
    }
  end

  defp traverse(ast, {_, issues}, _issue_meta, _allow_functions) do
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
