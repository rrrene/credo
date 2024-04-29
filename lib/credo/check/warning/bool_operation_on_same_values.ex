defmodule Credo.Check.Warning.BoolOperationOnSameValues do
  use Credo.Check,
    id: "EX5002",
    base_priority: :high,
    explanations: [
      check: """
      Boolean operations with identical values on the left and right side are
      most probably a logical fallacy or a copy-and-paste error.

      Examples:

          x && x
          x || x
          x and x
          x or x

      Each of these cases behaves the same as if you were just writing `x`.
      """
    ]

  @ops [:and, :or, :&&, :||]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:defmodule, _meta, _} = ast, issues, issue_meta) do
    redefined_ops = Credo.Code.prewalk(ast, &traverse_for_operator_redef(&1, &2))

    {ast, Credo.Code.prewalk(ast, &traverse_module(&1, &2, redefined_ops, issue_meta), issues)}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  for op <- @ops do
    defp traverse_module({unquote(op), meta, [lhs, rhs]} = ast, issues, redefined_ops, issue_meta) do
      op_not_redefined? = unquote(op) not in redefined_ops

      if op_not_redefined? && Credo.Code.remove_metadata(lhs) === Credo.Code.remove_metadata(rhs) do
        new_issue = issue_for(issue_meta, meta, unquote(op))
        {ast, [new_issue | issues]}
      else
        {ast, issues}
      end
    end
  end

  defp traverse_module(ast, issues, _redefined_ops, _issue_meta) do
    {ast, issues}
  end

  for op <- @ops do
    defp traverse_for_operator_redef(
           {:def, _,
            [
              {unquote(op), _, [_ | _]},
              [_ | _]
            ]} = ast,
           acc
         ) do
      {ast, acc ++ [unquote(op)]}
    end

    defp traverse_for_operator_redef(
           {:def, _,
            [
              {:when, _,
               [
                 {unquote(op), _, _} | _
               ]}
              | _
            ]} = ast,
           acc
         ) do
      {ast, acc ++ [unquote(op)]}
    end
  end

  defp traverse_for_operator_redef(ast, acc) do
    {ast, acc}
  end

  defp issue_for(issue_meta, meta, trigger) do
    format_issue(
      issue_meta,
      message:
        "There are identical sub-expressions to the left and to the right of the '#{trigger}' operator.",
      trigger: trigger,
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
