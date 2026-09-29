defmodule Credo.Check.Refactor.NegatedConditionsWithElse do
  use Credo.Check,
    id: "EX4019",
    base_priority: :high,
    explanations: [
      check: """
      An `if` block with a negated condition should not contain an else block.

      So while this is fine:

          if not allowed? do
            raise "Not allowed!"
          end

      The code in this example ...

          if not allowed? do
            raise "Not allowed!"
          else
            proceed_as_planned()
          end

      ... should be refactored to look like this:

          if allowed? do
            proceed_as_planned()
          else
            raise "Not allowed!"
          end

      The same goes for negation through `!` instead of `not`.

      A double negation like `!!allowed?` is not reported, since it is not a
      negated condition (it coerces the value to a boolean).

      The reason for this is not a technical but a human one. It is easier to wrap
      your head around a positive condition and then thinking "and else we do ...".

      In the above example raising the error in case something is not allowed
      might seem so important to put it first. But when you revisit this code a
      while later or have to introduce a colleague to it, you might be surprised
      how much clearer things get when the "happy path" comes first.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:if, meta, arguments} = ast, ctx) do
    negator = negated_condition(arguments)

    if negator && Credo.Code.Block.else_block?(ast) do
      {ast, put_issue(ctx, issue_for(ctx, meta, negator))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  # an even number of stacked negations (like `!!a`) is not a negated condition
  defp negated_condition({:!, _, _} = ast) do
    if odd_negations?(ast), do: "!"
  end

  defp negated_condition({:not, _, _} = ast) do
    if odd_negations?(ast), do: "not"
  end

  # parentheses around the condition wrap it in a __block__
  defp negated_condition({:__block__, _, arguments}) do
    negated_condition(arguments)
  end

  defp negated_condition(arguments) when is_list(arguments) do
    arguments |> List.first() |> negated_condition()
  end

  defp negated_condition(_), do: nil

  defp odd_negations?(ast), do: rem(count_negations(ast), 2) == 1

  defp count_negations({operator, _, [argument]}) when operator in [:!, :not] do
    1 + count_negations(argument)
  end

  defp count_negations({:__block__, _, [argument]}), do: count_negations(argument)

  defp count_negations(_), do: 0

  defp issue_for(ctx, meta, trigger) do
    format_issue(
      ctx,
      message: "Avoid negated conditions in if-else blocks.",
      trigger: trigger,
      line_no: meta[:line]
    )
  end
end
