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

  @bool_ops [:and, :or, :&&, :||]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:defmodule, _meta, _} = ast, ctx) do
    redefined_ops = Credo.Code.prewalk(ast, &find_bool_op_redefinition(&1, &2))
    ctx = Map.merge(ctx, %{redefined_ops: redefined_ops})

    {ast, Credo.Code.prewalk(ast, &walk_module/2, ctx)}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  for op <- @bool_ops do
    defp walk_module({unquote(op), meta, [lhs, rhs]} = ast, ctx) do
      op_not_redefined? = unquote(op) not in ctx.redefined_ops

      if op_not_redefined? && Credo.Code.remove_metadata(lhs) === Credo.Code.remove_metadata(rhs) do
        {ast, put_issue(ctx, issue_for(ctx, meta, unquote(op)))}
      else
        {ast, ctx}
      end
    end
  end

  defp walk_module(ast, ctx) do
    {ast, ctx}
  end

  for op <- @bool_ops do
    defp find_bool_op_redefinition({:def, _, [{unquote(op), _, [_ | _]}, [_ | _]]} = ast, acc) do
      {ast, acc ++ [unquote(op)]}
    end

    defp find_bool_op_redefinition(
           {:def, _, [{:when, _, [{unquote(op), _, _} | _]} | _]} = ast,
           acc
         ) do
      {ast, acc ++ [unquote(op)]}
    end
  end

  defp find_bool_op_redefinition(ast, acc) do
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
