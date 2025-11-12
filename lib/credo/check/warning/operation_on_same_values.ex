defmodule Credo.Check.Warning.OperationOnSameValues do
  use Credo.Check,
    id: "EX5011",
    base_priority: :high,
    explanations: [
      check: """
      Operations on the same values always yield the same result and therefore make
      little sense in production code.

      Examples:

          x == x  # always returns true
          x <= x  # always returns true
          x >= x  # always returns true
          x != x  # always returns false
          x > x   # always returns false
          y / y   # always returns 1
          y - y   # always returns 0

      In practice they are likely the result of a debugging session or were made by
      mistake.
      """
    ]

  @def_ops [:def, :defp, :defmacro]
  @ops ~w(== >= <= != > < / -)a
  @ops_and_constant_results [
    {:==, "Comparison", true},
    {:>=, "Comparison", true},
    {:<=, "Comparison", true},
    {:!=, "Comparison", false},
    {:>, "Comparison", false},
    {:<, "Comparison", false},
    {:/, "Operation", 1},
    {:-, "Operation", 0}
  ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  for op <- @def_ops do
    # exclude def arguments for operators
    defp walk({unquote(op), _meta, [{op, _, _} | rest]}, ctx) when op in @ops do
      {rest, ctx}
    end
  end

  for {op, operation_name, constant_result} <- @ops_and_constant_results do
    defp walk({unquote(op), meta, [lhs, rhs]} = ast, ctx) do
      if variable_or_mod_attribute?(lhs) &&
           Credo.Code.remove_metadata(lhs) == Credo.Code.remove_metadata(rhs) do
        new_issue =
          issue_for(ctx, meta, unquote(op), unquote(operation_name), unquote(constant_result))

        {ast, put_issue(ctx, new_issue)}
      else
        {ast, ctx}
      end
    end
  end

  # exclude @spec definitions
  defp walk({:@, _meta, [{:spec, _, _} | _]}, ctx) do
    {nil, ctx}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp variable_or_mod_attribute?({atom, _meta, nil}) when is_atom(atom), do: true
  defp variable_or_mod_attribute?({:@, _meta, list}) when is_list(list), do: true
  defp variable_or_mod_attribute?(_), do: false

  defp issue_for(ctx, meta, trigger, operation, constant_result) do
    format_issue(
      ctx,
      message: "#{operation} will always return #{constant_result}.",
      trigger: trigger,
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
