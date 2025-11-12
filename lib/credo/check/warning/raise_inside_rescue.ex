defmodule Credo.Check.Warning.RaiseInsideRescue do
  use Credo.Check,
    id: "EX5013",
    explanations: [
      check: """
      Using `Kernel.raise` inside of a `rescue` block creates a new stacktrace.

      Most of the time, this is not what you want to do since it obscures the cause of the original error.

      Example:

          # preferred

          try do
            raise "oops"
          rescue
            error ->
              Logger.warn("An exception has occurred")

              reraise error, System.stacktrace
          end

          # NOT preferred

          try do
            raise "oops"
          rescue
            error ->
              Logger.warn("An exception has occurred")

              raise error
          end
      """
    ]

  alias Credo.Code.Block

  @def_ops [:def, :defp, :defmacro, :defmacrop]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:try, _meta, _arguments} = ast, ctx) do
    case Block.rescue_block_for(ast) do
      {:ok, rescue_block} -> {ast, Credo.Code.prewalk(rescue_block, &find_issues/2, ctx)}
      _ -> {ast, ctx}
    end
  end

  defp walk({op, _meta, [_def, [do: _do, rescue: rescue_block]]}, ctx)
       when op in @def_ops do
    {rescue_block, Credo.Code.prewalk(rescue_block, &find_issues/2, ctx)}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp find_issues({:raise, meta, _arguments} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp find_issues(ast, ctx), do: {ast, ctx}

  defp issue_for(ctx, meta) do
    format_issue(
      ctx,
      message: "Use `reraise` inside a rescue block to preserve the original stacktrace.",
      trigger: "raise",
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
