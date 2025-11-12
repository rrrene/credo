defmodule Credo.Check.Refactor.CondStatements do
  use Credo.Check,
    id: "EX4005",
    explanations: [
      check: """
      Each cond statement should have 3 or more statements including the
      "always true" statement.

      Consider an `if`/`else` construct if there is only one condition and the
      "always true" statement, since it will more accessible to programmers
      new to the codebase (and possibly new to Elixir).

      Example:

          cond do
            x == y -> 0
            true -> 1
          end

          # should be written as

          if x == y do
            0
          else
            1
          end

      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:cond, meta, arguments} = ast, ctx) do
    conditions =
      arguments
      |> Credo.Code.Block.do_block_for!()
      |> List.wrap()

    count = Enum.count(conditions)

    should_be_written_as_if_else_block? =
      count <= 2 && contains_always_matching_condition?(conditions)

    if should_be_written_as_if_else_block? do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp contains_always_matching_condition?(conditions) do
    Enum.any?(conditions, fn
      {:->, _meta, [[{name, _meta2, nil}], _args]} when is_atom(name) ->
        name |> to_string |> String.starts_with?("_")

      {:->, _meta, [[true], _args]} ->
        true

      _ ->
        false
    end)
  end

  defp issue_for(issue_meta, meta) do
    format_issue(
      issue_meta,
      message:
        "Cond statements should contain at least two conditions besides `true`, consider using `if` instead.",
      trigger: "cond",
      line_no: meta[:line]
    )
  end
end
