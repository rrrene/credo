defmodule Credo.Check.Readability.RedundantBlankLines do
  use Credo.Check,
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

  alias Credo.Code.Charlists
  alias Credo.Code.Heredocs
  alias Credo.Code.Sigils
  alias Credo.Code.Strings

  @doc false
  # TODO: consider for experimental check front-loader (text)
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    max_blank_lines = Params.get(params, :max_blank_lines, __MODULE__)

    source_file
    |> Charlists.replace_with_spaces("=")
    |> Sigils.replace_with_spaces("=", "=", source_file.filename)
    |> Strings.replace_with_spaces("=", "=", source_file.filename)
    |> Heredocs.replace_with_spaces("=", "=", "=", source_file.filename)
    |> Credo.Code.to_lines()
    |> blank_lines()
    |> consecutive_lines(max_blank_lines)
    |> Enum.map(fn line -> issue_for(issue_meta, line, max_blank_lines) end)
  end

  defp issue_for(issue_meta, line, max_blank_lines) do
    format_issue(
      issue_meta,
      message: "There should be no more than #{max_blank_lines} consecutive blank lines.",
      line_no: line
    )
  end

  defp blank_lines(lines) do
    lines
    |> Enum.filter(fn {_, content} -> content == "" end)
    |> Enum.map(fn {pos, _} -> pos end)
  end

  defp consecutive_lines([], _), do: []

  defp consecutive_lines([first_line | other_lines], max_blank_lines) do
    reducer = consecutive_lines_reducer(max_blank_lines)

    other_lines
    |> Enum.reduce({first_line, 0, []}, reducer)
    |> elem(2)
  end

  defp consecutive_lines_reducer(max_blank_lines) do
    fn line, {last, consecutive, lines} ->
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
    end
  end
end
