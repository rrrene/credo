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
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:@, meta, [{:impl, _, [true]}]}, issues, issue_meta) do
    {nil, issues ++ [issue_for(issue_meta, meta[:line])]}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "`@impl true` should be `@impl MyBehaviour`.",
      trigger: "@impl",
      line_no: line_no
    )
  end
end
