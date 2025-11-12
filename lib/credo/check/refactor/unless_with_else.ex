defmodule Credo.Check.Refactor.UnlessWithElse do
  use Credo.Check,
    id: "EX4027",
    base_priority: :high,
    explanations: [
      check: """
      An `unless` block should not contain an else block.

      So while this is fine:

          unless allowed? do
            raise "Not allowed!"
          end

      This should be refactored:

          unless allowed? do
            raise "Not allowed!"
          else
            proceed_as_planned()
          end

      to look like this:

          if allowed? do
            proceed_as_planned()
          else
            raise "Not allowed!"
          end

      The reason for this is not a technical but a human one. The `else` in this
      case will be executed when the condition is met, which is the opposite of
      what the wording seems to imply.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:@, _, [{:unless, _, _}]}, ctx) do
    {nil, ctx}
  end

  defp walk({:unless, meta, _arguments} = ast, ctx) do
    if Credo.Code.Block.else_block?(ast) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta) do
    format_issue(
      ctx,
      message: "Unless conditions should avoid having an `else` block.",
      trigger: "unless",
      line_no: meta[:line]
    )
  end
end
