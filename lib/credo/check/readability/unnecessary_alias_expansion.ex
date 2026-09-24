defmodule Credo.Check.Readability.UnnecessaryAliasExpansion do
  use Credo.Check,
    id: "EX3030",
    base_priority: :low,
    explanations: [
      check: """
      Alias expansion is useful but when aliasing a single module,
      it can be harder to read with unnecessary braces.

          # preferred

          alias ModuleA.Foo
          alias ModuleA.{Foo, Bar}

          # NOT preferred

          alias ModuleA.{Foo}

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ],
    managed_traversal: :ast

  def handle_walk({:alias, _, [{{:., _, [_, :{}]}, _, [{:__aliases__, meta, [child]}]}]} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta, child))}
  end

  def handle_walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta, trigger) do
    format_issue(
      ctx,
      message: "Unnecessary alias expansion for #{trigger}, consider removing braces.",
      trigger: trigger,
      line_no: meta[:line]
    )
  end
end
