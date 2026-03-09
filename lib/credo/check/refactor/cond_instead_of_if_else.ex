defmodule Credo.Check.Refactor.CondInsteadOfIfElse do
  use Credo.Check,
    id: "EX4033",
    base_priority: :low,
    param_defaults: [allow_one_liners: false],
    explanations: [
      check: """
      Prefer `cond` over `if/else` blocks.

      So while this is fine:

          if allowed? do
            :ok
          end

      The use of `else` could impact readability:

          if allowed? do
            :ok
          else
            :error
          end

      and could be improved to:

          cond do
            allowed? -> :ok
            true -> :error
          end

      There's no technical reason for this; it's a matter of preferred code style.

      NOTE: This check is mutually exclusive with `Credo.Check.Refactor.CondStatements`,
      which recommends the opposite. Enable only one of these checks.
      """,
      params: [
        allow_one_liners: "Allow one-liner `if/else` expressions (e.g., `if x, do: y, else: z`)."
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:@, _, [{:if, _, _}]}, ctx) do
    {nil, ctx}
  end

  defp walk({:if, meta, _arguments} = ast, %{params: %{allow_one_liners: true}} = ctx) do
    if Credo.Code.Block.else_block?(ast) and block_if?(meta) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk({:if, meta, _arguments} = ast, ctx) do
    if Credo.Code.Block.else_block?(ast) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  # Block if/else has :end key in metadata, inline does not
  defp block_if?(meta), do: Keyword.has_key?(meta, :end)

  defp issue_for(ctx, meta) do
    format_issue(
      ctx,
      message: "Consider using `cond` instead of `if/else`.",
      trigger: "if",
      line_no: meta[:line]
    )
  end
end
