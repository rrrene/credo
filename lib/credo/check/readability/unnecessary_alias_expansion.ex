defmodule Credo.Check.Readability.UnnecessaryAliasExpansion do
  use Credo.Check,
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
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # TODO: consider for experimental check front-loader (ast)
  defp traverse(
         {:alias, _, [{{:., _, [_, :{}]}, _, [{:__aliases__, opts, [child]}]}]} = ast,
         issues,
         issue_meta
       ) do
    {ast, issues ++ [issue_for(issue_meta, Keyword.get(opts, :line), child)]}
  end

  defp traverse(ast, issues, _issue_meta), do: {ast, issues}

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Unnecessary alias expansion for #{trigger}, consider removing braces.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
