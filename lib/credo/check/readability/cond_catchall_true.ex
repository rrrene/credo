defmodule Credo.Check.Readability.CondCatchallTrue do
  use Credo.Check,
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
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:cond, meta, arguments} = ast, issues, issue_meta) do
    conditions =
      arguments
      |> Credo.Code.Block.do_block_for!()
      |> List.wrap()

    if conditions
      |> List.last()
      |> catchall_other_than_true?() do
      {ast, issues ++ [issue_for(issue_meta, meta[:line], :cond)]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp catchall_other_than_true?({:->, _meta, [[true], _args]}), do: false
  # Integer literal catch-all clause
  defp catchall_other_than_true?({:->, _meta, ['{', _args]}), do: true
  # Binary literal catch-all clause
  defp catchall_other_than_true?({:->, _meta, [[binary], _args]}) when is_binary(binary), do: true
  # List literal catch-all clause
  defp catchall_other_than_true?({:->, _meta, [[list], _args]}) when is_list(list), do: true
  # Map literal catch-all clause
  defp catchall_other_than_true?({:->, _meta, [[{:%{}, _meta2, []}], _args]}), do: true
  # Tuple literal catch-all clause
  defp catchall_other_than_true?({:->, _meta, [[{:{}, _meta2, _values}], _args]}), do: true
  # Atom literal catch-all clause
  defp catchall_other_than_true?({:->, _meta, [[name], _args]}) when is_atom(name), do: true
  defp catchall_other_than_true?(_), do: false

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
