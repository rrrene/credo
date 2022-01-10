defmodule Credo.Check.Readability.CondFinalCondition do
  use Credo.Check,
    # Default to the value specified here:
    # https://github.com/christopheradams/elixir_style_guide#true-as-last-condition
    param_defaults: [final_condition_value: true],
    explanations: [
      check: """
      If a cond expresion ends in an "always true" statement. That last
      statement should be simply `true`. Other literal truthy values (such as
      `:else`, `:always`, etc... aren't allowed.

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
      """,
      params: [
        final_condition_value: "Set the expected value for the final condition"
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    final_condition_value = Params.get(params, :final_condition_value, __MODULE__)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, final_condition_value))
  end

  defp traverse({:cond, meta, arguments} = ast, issues, issue_meta, final_condition_value) do
    conditions =
      arguments
      |> Credo.Code.Block.do_block_for!()
      |> List.wrap()

    if conditions
      |> List.last()
      |> catchall_other_than_value?(final_condition_value) do
      {ast, issues ++ [issue_for(issue_meta, meta[:line], :cond)]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta, _min_pipeline_length) do
    {ast, issues}
  end

  defp catchall_other_than_value?({:->, _meta, [[value], _args]}, value), do: false
  # Integer literal catch-all clause
  defp catchall_other_than_value?({:->, _meta, ['{', _args]}, _value), do: true
  # Binary literal catch-all clause
  defp catchall_other_than_value?({:->, _meta, [[binary], _args]}, _value) when is_binary(binary), do: true
  # List literal catch-all clause
  defp catchall_other_than_value?({:->, _meta, [[list], _args]}, _value) when is_list(list), do: true
  # Map literal catch-all clause
  defp catchall_other_than_value?({:->, _meta, [[{:%{}, _meta2, []}], _args]}, _value), do: true
  # Tuple literal catch-all clause
  defp catchall_other_than_value?({:->, _meta, [[{:{}, _meta2, _values}], _args]}, _value), do: true
  # Atom literal catch-all clause
  defp catchall_other_than_value?({:->, _meta, [[name], _args]}, _value) when is_atom(name), do: true
  defp catchall_other_than_value?(_clause, _value), do: false

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message:
      "Cond statements that end with an \"always true\" condition should use `true` instead of some other literal.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
