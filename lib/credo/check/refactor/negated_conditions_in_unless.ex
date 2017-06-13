defmodule Credo.Check.Refactor.NegatedConditionsInUnless do
  @moduledoc """
  Unless blocks should not contain a negated condition.

  The code in this example ...

      unless !allowed? do
        proceed_as_planned()
      end

  ... should be refactored to look like this:

      if allowed? do
        proceed_as_planned()
      end

  The reason for this is not a technical but a human one. It is pretty difficult
  to wrap your head around a block of code that is executed if a negated
  condition is NOT met. See what I mean?
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:@, _, [{:unless, _, _}]}, issues, _issue_meta) do
    {nil, issues}
  end
  defp traverse({:unless, meta, arguments} = ast, issues, issue_meta) when is_list(arguments) do
    issue = issue_for_first_condition(List.first(arguments), meta, issue_meta)

    {ast, issues ++ List.wrap(issue)}
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for_first_condition({:!, meta, _arguments}, meta, issue_meta) do
    issue_for(issue_meta, meta[:line], "!")
  end
  defp issue_for_first_condition(_, _, _), do: nil


  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "Avoid negated conditions in unless blocks.",
      trigger: trigger,
      line_no: line_no
  end
end
