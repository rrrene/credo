defmodule Credo.Check.Readability.PipesToAnonymousFunctions do
  @moduledoc false

  @checkdoc """
  Do not pipe into anonymous functions.

  So while this is fine:
      foo
      |> times_2()
      |> times_2()
  The code in this example ...
      foo
      |> (fn i -> i * 2 end).()
      |> (fn i -> i * 2 end).()
  ... should be refactored to look like this:
      defp timex_2(i), do: i * 2

      foo
      |> times_2()
      |> times_2()
  Piping into anonymous functions is cluttered and difficult to read.
  Instead, define a private function and use that instead.
  """
  @explanation [check: @checkdoc]

  use Credo.Check, base_priority: :high

  @doc false
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
      message: "Do not pipe into anonymous function calls",
      trigger: "anonymous_functions_in_pipes",
      line_no: line_no
    )
  end
end
