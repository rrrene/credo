defmodule Credo.Check.Readability.SingleFunctionToBlockPipe do
  use Credo.Check,
    tags: [:controversial],
    explanations: [
      check: """
      A single pipe (`|>`) should not be used to pipe into blocks.

      The code in this example ...

          list
          |> length()
          |> case do
            0 -> :none
            1 -> :one
            _ -> :many
          end

      ... should be refactored to look like this:

          case length(list) do
            0 -> :none
            1 -> :one
            _ -> :many
          end

      If you want to disallow piping into blocks all together, use
      `Credo.Check.Readability.BlockPipe`.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    Credo.Code.prewalk(source_file, &traverse(&1, &2, IssueMeta.for(source_file, params)))
  end

  defp traverse(ast, {false, issues}, _issue_meta) do
    {ast, issues}
  end

  defp traverse(ast, issues, issue_meta) do
    case issue(ast, issue_meta) do
      nil -> {ast, issues}
      false -> {ast, {false, issues}}
      issue -> {ast, [issue | issues]}
    end
  end

  defp issue({:|>, _, [{:|>, _, [{:|>, _, _} | _]} | _]}, _), do: false

  defp issue({:|>, meta, [arg, {marker, _case_meta, _case_args}]}, issue_meta)
       when marker in [:case, :if] do
    if issue?(arg), do: issue_for(issue_meta, meta[:line]), else: nil
  end

  defp issue(_, _), do: nil

  defp issue?({_, _, nil}), do: true

  defp issue?({:%{}, _, _}), do: true

  defp issue?(arg) when is_list(arg), do: true

  defp issue?({:|>, _, [{_, _, nil}, {_, _, args}]}) when is_list(args), do: true

  defp issue?({:|>, _, [{:%{}, _, _}, {_, _, args}]}) when is_list(args), do: true

  defp issue?({:|>, _, [arg, {_, _, args}]}) when is_list(arg) and is_list(args), do: true

  defp issue?(_), do: false

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "Avoid single pipes to a block",
      line_no: line_no
    )
  end
end
