defmodule Credo.Check.Readability.RedundantBlankLines do
  use Credo.Check,
    id: "EX3019",
    base_priority: :low,
    tags: [:formatter],
    param_defaults: [max_blank_lines: 1],
    explanations: [
      check: """
      Files should not have two or more consecutive blank lines.

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """,
      params: [
        max_blank_lines: "The maximum number of tolerated consecutive blank lines."
      ]
    ]

  import CredoTokenizer.Guards

  @doc false
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    max_blank_lines = Params.get(params, :max_blank_lines, __MODULE__)

    source_file
    |> Credo.Code.Token.reduce(&collect_blank_lines(&1, &2, &3, &4))
    |> Enum.reverse()
    |> consecutive_lines(max_blank_lines)
    |> Enum.map(fn line -> issue_for(issue_meta, line, max_blank_lines) end)
  end

  defp collect_blank_lines(left, {_, {line, _, _, _}, _, _} = right, _next, acc) when is_eol(left) and is_eol(right) do
    [line | acc]
  end

  defp collect_blank_lines(_prev, _current, _next, acc), do: acc

  defp consecutive_lines([], _), do: []

  defp consecutive_lines([first_line | other_lines], max_blank_lines) do
    other_lines
    |> Enum.reduce({first_line, 0, []}, fn line, {last, consecutive, lines} ->
      consecutive =
        if last && line == last + 1 do
          consecutive + 1
        else
          0
        end

      lines =
        if consecutive >= max_blank_lines do
          lines ++ [line]
        else
          lines
        end

      {line, consecutive, lines}
    end)
    |> elem(2)
  end

  defp issue_for(issue_meta, line, max_blank_lines) do
    format_issue(
      issue_meta,
      message: "There should be no more than #{max_blank_lines} consecutive blank lines.",
      line_no: line,
      trigger: Issue.no_trigger()
    )
  end
end
