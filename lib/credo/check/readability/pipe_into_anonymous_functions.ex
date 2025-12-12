defmodule Credo.Check.Readability.PipeIntoAnonymousFunctions do
  use Credo.Check,
    id: "EX3015",
    base_priority: :low,
    explanations: [
      check: """
      Avoid piping into anonymous functions.

      The code in this example ...

          def my_fun(foo) do
            foo
            |> (fn i -> i * 2 end).()
            |> my_other_fun()
          end

      ... should be refactored to define a private function:

          def my_fun(foo) do
            foo
            |> times_2()
            |> my_other_fun()
          end

          defp times_2(i), do: i * 2

      ... or use `then/1`:

          def my_fun(foo) do
            foo
            |> then(fn i -> i * 2 end)
            |> my_other_fun()
          end

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @impl true
  def run(source_file, params \\ []) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:|>, meta, [_, {{:., _, [{:fn, _, _} | _]}, _, _}]} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta) do
    format_issue(
      ctx,
      message: "Avoid piping into anonymous function calls.",
      trigger: "|>",
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
