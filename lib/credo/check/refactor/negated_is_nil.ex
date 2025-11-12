defmodule Credo.Check.Refactor.NegatedIsNil do
  use Credo.Check,
    id: "EX4020",
    base_priority: :low,
    tags: [:controversial],
    explanations: [
      check: """
      We should avoid negating the `is_nil` predicate function.

      For example, the code here ...

          def fun(%{external_id: external_id, id: id}) when not is_nil(external_id) do
             # ...
          end

      ... can be refactored to look like this:

          def fun(%{external_id: nil, id: id}) do
            # ...
          end

          def fun(%{external_id: external_id, id: id}) do
            # ...
          end

      ... or even better, can match on what you were expecting on the first place:

          def fun(%{external_id: external_id, id: id}) when is_binary(external_id) do
            # ...
          end

          def fun(%{external_id: nil, id: id}) do
            # ...
          end

          def fun(%{external_id: external_id, id: id}) do
            # ...
          end

      Similar to negating `unless` blocks, the reason for this check is not
      technical, but a human one. If we can use the positive, more direct and human
      friendly case, we should.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:when, _, [_, {negation, meta, [{:is_nil, _, _}]}]} = ast, ctx)
       when negation in [:!, :not] do
    trigger = to_string(negation)

    issue =
      format_issue(
        ctx,
        message: "Avoid negated `is_nil/1` in guard clauses.",
        trigger: trigger,
        line_no: meta[:line]
      )

    {ast, put_issue(ctx, issue)}
  end

  defp walk({:when, meta, [fun, {_, _, [first_op | second_op]}]} = ast, ctx) do
    {_, ctx} = walk({:when, meta, [fun, first_op]}, ctx)
    {_, ctx} = walk({:when, meta, [fun, second_op]}, ctx)

    {ast, ctx}
  end

  defp walk(ast, ctx), do: {ast, ctx}
end
