defmodule Credo.Check.Refactor.NegatedConditionsInUnless do
  use Credo.Check,
    id: "EX4018",
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
    ],
    managed_traversal: :ast

  def handle_walk({:@, _, [{:unless, _, _}]}, ctx) do
    {nil, ctx}
  end

  def handle_walk({:unless, _meta, [{negator, meta, _arguments} | _]} = ast, ctx)
      when negator in [:!, :not] do
    {ast, put_issue(ctx, issue_for(ctx, meta, negator))}
  end

  def handle_walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta, trigger) do
    format_issue(
      ctx,
      message: "Avoid negated conditions in unless blocks.",
      trigger: trigger,
      line_no: meta[:line]
    )
  end
end
