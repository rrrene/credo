defmodule Credo.Check.Warning.OperationOnSameValues do
  use Credo.Check,
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
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # TODO: consider for experimental check front-loader (ast)
  for op <- @def_ops do
    # exclude def arguments for operators
    defp traverse(
           {unquote(op), _meta, [{op, _, _} | rest]},
           issues,
           _issue_meta
         )
         when op in @ops do
      {rest, issues}
    end
  end

  for {op, operation_name, constant_result} <- @ops_and_constant_results do
    defp traverse({unquote(op), meta, [lhs, rhs]} = ast, issues, issue_meta) do
      if variable_or_mod_attribute?(lhs) &&
           Credo.Code.remove_metadata(lhs) == Credo.Code.remove_metadata(rhs) do
        new_issue =
          issue_for(
            issue_meta,
            meta[:line],
            unquote(op),
            unquote(operation_name),
            unquote(constant_result)
          )

        {ast, issues ++ [new_issue]}
      else
        {ast, issues}
      end
    end
  end

  defp variable_or_mod_attribute?({atom, _meta, nil}) when is_atom(atom), do: true
  defp variable_or_mod_attribute?({:@, _meta, list}) when is_list(list), do: true
  defp variable_or_mod_attribute?(_), do: false

  # exclude @spec definitions
  defp traverse({:@, _meta, [{:spec, _, _} | _]}, issues, _issue_meta) do
    {nil, issues}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, trigger, operation, constant_result) do
    format_issue(
      issue_meta,
      message: "#{operation} will always return #{constant_result}.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
