defmodule Credo.Check.Readability.TrailingWhiteSpace do
  use Credo.Check,
    id: "EX3029",
    base_priority: :low,
    tags: [:formatter],
    param_defaults: [
      ignore_strings: true
    ],
    explanations: [
      check: """
      There should be no white-space (i.e. tabs, spaces) at the end of a line.

      Most text editors provide a way to remove them automatically.

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """,
      params: [
        ignore_strings: "Set to `false` to check lines that are strings or in heredocs"
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)

    result = Credo.Code.Token.reduce(source_file, &collect/4, ctx)
    result.issues
  end

  defp collect(
         _prev,
         {{type, _}, {line, _, line2, _}, [first | _], _},
         _next,
         %{params: %{ignore_strings: false}} = ctx
       )
       when type in [:string, :heredoc] and not is_integer(first) do
    do_collect_from_string(ctx, line, line2)
  end

  defp collect(_, {_, {_, _, line, col}, _, _}, {{:eol, _}, {line, col, _, _}, _, _}, ctx) do
    ctx
  end

  defp collect(_, {_, {_, _, line, col}, _, _}, {{:eol, _}, {line, col2, _, _}, _, _}, ctx) do
    put_issue(ctx, issue_for(ctx, line, col, col2))
  end

  defp collect(_prev, _current, _next, ctx) do
    ctx
  end

  defp indent(lines) do
    {_, string} = List.last(lines)
    [{_column, indent}] = Regex.run(~r/^\s*/, string, return: :index)
    indent
  end

  defp do_collect_from_string(ctx, line, line2) do
    lines =
      Enum.map(line..line2, fn line_no ->
        {line_no, SourceFile.line_at(ctx.source_file, line_no)}
      end)

    indent = indent(lines)

    Enum.reduce(lines, ctx, fn {line_no, line}, ctx ->
      case Regex.run(~r/\h+$/u, line, return: :index) do
        [{column, trailing_spaces}] ->
          if column > indent do
            put_issue(ctx, issue_for(ctx, line_no, column + 1, column + 1 + trailing_spaces))
          else
            ctx
          end

        nil ->
          ctx
      end
    end)
  end

  defp issue_for(ctx, line_no, column, line_length) do
    format_issue(
      ctx,
      message: "There should be no trailing white-space at the end of a line.",
      line_no: line_no,
      column: column,
      trigger: String.duplicate(" ", line_length - column)
    )
  end
end
