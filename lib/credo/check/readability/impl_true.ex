defmodule Credo.Check.Readability.ImplTrue do
  use Credo.Check,
    id: "EX3004",
    base_priority: :normal,
    explanations: [
      check: """
      `@impl true` is a shortform so you don't have to write the actual behaviour that is being implemented.
      This can make code harder to comprehend.

      # preferred

          @impl MyBehaviour
          def my_funcion() do
            # ...
          end

      # NOT preferred

          @impl true
          def my_funcion() do
            # ...
          end

      When implementing behaviour callbacks, `@impl true` indicates that a function implements a callback, but
      a more explicit way is to use the actual behaviour being implemented, for example `@impl MyBehaviour`.

      This not only improves readability, but adds extra validation in cases where multiple behaviours are
      implemented in a single module.

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:@, meta, [{:impl, _, [true]}]}, ctx) do
    {nil, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta) do
    format_issue(
      ctx,
      message: "`@impl true` should be `@impl MyBehaviour`.",
      trigger: "@impl",
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
