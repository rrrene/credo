defmodule Credo.Check.Readability.SinglePipe do
  @moduledoc """
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
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    {_continue, issues} =
      Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta), {true, []})

    issues
  end

  defp traverse({:|>, _, [{:|>, _, _} | _]} = ast, {_, issues}, _) do
    {ast, {false, issues}}
  end

  defp traverse({:|>, meta, _} = ast, {true, issues}, issue_meta) do
    {ast, {false, issues ++ [issue_for(issue_meta, meta[:line], "single pipe")]}}
  end

  defp traverse(ast, {_, issues}, _issue_meta) do
    {ast, {true, issues}}
  end

  def issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "Use a function call when a pipeline is only one function long",
      trigger: trigger,
      line_no: line_no
  end
end
