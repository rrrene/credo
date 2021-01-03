defmodule Credo.Check.Readability.PipeIntoAnonymousFunctions do
  use Credo.Check,
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

          defp timex_2(i), do: i * 2

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @impl true
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse(
         {:|>, meta, [_, {{:., _, [{:fn, _, _} | _]}, _, _}]} = ast,
         issues,
         issue_meta
       ) do
    {ast, [issue_for(issue_meta, meta[:line]) | issues]}
  end

  defp traverse(ast, issues, _) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "Avoid piping into anonymous function calls",
      trigger: "|>",
      line_no: line_no
    )
  end
end
