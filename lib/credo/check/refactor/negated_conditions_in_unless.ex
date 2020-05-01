defmodule Credo.Check.Refactor.NegatedConditionsInUnless do
  use Credo.Check,
    base_priority: :high,
    explanations: [
      check: """
      Unless blocks should avoid having a negated condition.

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
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:@, _, [{:unless, _, _}]}, issues, _issue_meta) do
    {nil, issues}
  end

  # TODO: consider for experimental check front-loader (ast)
  # NOTE: we have to exclude the cases matching the above clause!
  defp traverse({:unless, _meta, arguments} = ast, issues, issue_meta)
       when is_list(arguments) do
    issue = issue_for_first_condition(List.first(arguments), issue_meta)

    {ast, issues ++ List.wrap(issue)}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for_first_condition({:!, meta, _arguments}, issue_meta) do
    issue_for(issue_meta, meta[:line], "!")
  end

  defp issue_for_first_condition(_, _), do: nil

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Avoid negated conditions in unless blocks.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
