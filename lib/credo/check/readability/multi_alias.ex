defmodule Credo.Check.Readability.MultiAlias do
  use Credo.Check,
    id: "EX3011",
    base_priority: :low,
    tags: [:controversial],
    explanations: [
      check: """
      Multi alias expansion makes module uses harder to search for in large code bases.

          # preferred

          alias Module.Foo
          alias Module.Bar

          # NOT preferred

          alias Module.{Foo, Bar}

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

  defp walk(
         {:alias, _,
          [{{_, _, [{alias_op, meta, _base_alias}, :{}]}, _, [{:__aliases__, _, mod_list} | _]}]} =
           ast,
         ctx
       )
       when alias_op in [:__aliases__, :__MODULE__] do
    module = Credo.Code.Name.full(mod_list)

    {ast, put_issue(ctx, issue_for(ctx, meta[:line], module))}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp issue_for(ctx, line_no, trigger) do
    format_issue(
      ctx,
      message:
        "Avoid grouping aliases in '{ ... }'; please specify one fully-qualified alias per line.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
