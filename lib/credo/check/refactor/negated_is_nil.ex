defmodule Credo.Check.Refactor.NegatedIsNil do
  use Credo.Check,
    base_priority: :low,
    tags: [:controversial],
    explanations: [
      check: """
      We should avoid negating the `is_nil` predicate function.
      Here are a couple of examples:
      The code here ...
          def fun(%{external_id: external_id, id: id}) when not is_nil(external_id) do
             ...
          end

      ... can be refactored to look like this:
          def fun(%{external_id: nil, id: id}) do
            ...
          end
          def fun(%{external_id: external_id, id: id}) do
            ...
          end

      ... or even better, can match on what you were expecting on the first place:
          def fun(%{external_id: external_id, id: id}) when is_binary(external_id) do
            ...
          end
          def fun(%{external_id: nil, id: id}) do
            ...
          end
          def fun(%{external_id: external_id, id: id}) do
            ...
          end

      Similar to negating unless blocks, the reason for this check is not
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
    issue =
      format_issue(
        issue_meta,
        message: "Negated is_nil in guard clause found",
        trigger: "when !/not is_nil",
        line_no: meta[:line]
      )

    {ast, [issue | issues]}
  end

  defp traverse(ast, issues, _), do: {ast, issues}
end
