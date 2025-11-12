defmodule Credo.Check.Readability.SinglePipe do
  use Credo.Check,
    id: "EX3023",
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
    ctx = Context.build(source_file, params, __MODULE__, %{continue: true})
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:|>, _, [{:|>, _, _} | _]} = ast, ctx) do
    {ast, %{ctx | continue: false}}
  end

  defp walk(
         {:|>, meta, _} = ast,
         %{continue: true, params: %{allow_0_arity_functions: false}} = ctx
       ) do
    {
      ast,
      put_issue(%{ctx | continue: false}, issue_for(ctx, meta))
    }
  end

  defp walk(
         {:|>, _, [{{:., _, _}, _, []}, _]} = ast,
         %{continue: true, params: %{allow_0_arity_functions: true}} = ctx
       ) do
    {ast, %{ctx | continue: false}}
  end

  defp walk(
         {:|>, _, [{fun, _, []}, _]} = ast,
         %{continue: true, params: %{allow_0_arity_functions: true}} = ctx
       )
       when is_atom(fun) do
    {ast, %{ctx | continue: false}}
  end

  defp walk(
         {:|>, meta, _} = ast,
         %{continue: true, params: %{allow_0_arity_functions: true}} = ctx
       ) do
    {
      ast,
      put_issue(%{ctx | continue: false}, issue_for(ctx, meta))
    }
  end

  defp walk(ast, ctx) do
    {ast, %{ctx | continue: true}}
  end

  defp issue_for(ctx, meta) do
    format_issue(
      ctx,
      message: "Use a function call when a pipeline is only one function long.",
      trigger: "|>",
      line_no: meta[:line]
    )
  end
end
