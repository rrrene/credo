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
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:when, meta, [_, {negation, _, [{:is_nil, _, _}]}]} = ast, issues, issue_meta)
       when negation in [:!, :not] do
    trigger = to_string(negation)

    issue =
      format_issue(
        issue_meta,
        message: "Avoid negated `is_nil/1` in guard clauses.",
        trigger: trigger,
        line_no: meta[:line]
      )

    {ast, [issue | issues]}
  end

  defp traverse({:when, meta, [fun, {_, _, [first_op | second_op]}]} = ast, issues, issue_meta) do
    {_, first_op_issues} = traverse({:when, meta, [fun, first_op]}, [], issue_meta)
    {_, second_op_issues} = traverse({:when, meta, [fun, second_op]}, [], issue_meta)

    {ast, first_op_issues ++ second_op_issues ++ issues}
  end

  defp traverse(ast, issues, _), do: {ast, issues}
end
