defmodule Credo.Check.Readability.CondFinalCondition do
  use Credo.Check,
    tags: [:controversial],
    # Default to the value specified here:
    # https://github.com/christopheradams/elixir_style_guide#true-as-last-condition
    param_defaults: [value: true],
    explanations: [
      check: """
      If a cond expresion ends in an "always true" statement the statement
      should be the literal `true`, or the literal value specified in this
      check's `value` parameter.

      Example:

          cond do
            x == y -> 0
            x > y -> 0
            :else -> 1
          end

          # should be written as

          cond do
            x == y -> 0
            x > y -> 0
            true -> 1
          end

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of other reading and liking your code by making
      it easier to follow.
      """,
      params: [
        value: "Set the expected value for the final condition"
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    config_catchall_value = Params.get(params, :value, __MODULE__)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, config_catchall_value))
  end

  defp traverse({:cond, meta, arguments} = ast, issues, issue_meta, config_catchall_value) do
    last_cond_clause =
      arguments
      |> Credo.Code.Block.do_block_for!()
      |> List.wrap()
      |> List.last()

    case is_catchall_clause_with_invalid_value?(last_cond_clause, config_catchall_value) do
      {true, ast} ->
        expression = Macro.to_string(ast)
        {ast, issues ++ [issue_for(issue_meta, config_catchall_value, meta[:line], expression)]}

      _ ->
        {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta, _min_pipeline_length) do
    {ast, issues}
  end

  defp is_catchall_clause_with_invalid_value?({:->, _meta, [[value], _args]}, value), do: false
  # Integer literal catch-all clause
  defp is_catchall_clause_with_invalid_value?({:->, _meta, [[integer], _args]}, _value)
       when is_integer(integer),
       do: {true, integer}

  # Binary literal catch-all clause
  defp is_catchall_clause_with_invalid_value?({:->, _meta, [[binary], _args]}, _value)
       when is_binary(binary),
       do: {true, binary}

  # List literal catch-all clause
  defp is_catchall_clause_with_invalid_value?({:->, _meta, [[list], _args]}, _value)
       when is_list(list),
       do: {true, list}

  # Map literal catch-all clause
  defp is_catchall_clause_with_invalid_value?(
         {:->, _meta, [[{:%{}, _meta2, _values} = ast], _args]},
         _value
       ),
       do: {true, ast}

  # Tuple literal catch-all clause
  defp is_catchall_clause_with_invalid_value?(
         {:->, _meta, [[{:{}, _meta2, _values} = ast], _args]},
         _value
       ),
       do: {true, ast}

  # Atom literal catch-all clause
  defp is_catchall_clause_with_invalid_value?({:->, _meta, [[name], _args]}, _value)
       when is_atom(name),
       do: {true, name}

  # Any other cond clause expression
  defp is_catchall_clause_with_invalid_value?(_clause, _value), do: false

  defp issue_for(issue_meta, expected_value, line_no, trigger) do
    format_issue(
      issue_meta,
      message:
        "Cond statements that end with an \"always true\" condition should use `#{expected_value}` instead of some other literal.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
