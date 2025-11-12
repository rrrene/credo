defmodule Credo.Check.Readability.ModuleAttributeNames do
  use Credo.Check,
    id: "EX3008",
    base_priority: :high,
    explanations: [
      check: """
      Module attribute names are always written in snake_case in Elixir.

          # snake_case

          @inbox_name "incoming"

          # not snake_case

          @inboxName "incoming"

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  alias Credo.Code.Name

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # ignore non-alphanumeric @ ASTs, for when you're redefining the @ macro.
  defp walk({:@, _meta, [{:{}, _, _}]} = ast, ctx) do
    {ast, ctx}
  end

  defp walk({:@, meta, [{name, _, _arguments}]} = ast, ctx) when is_atom(name) do
    if name |> to_string |> Name.snake_case?() do
      {ast, ctx}
    else
      {ast, put_issue(ctx, issue_for(ctx, meta, "@#{name}"))}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta, trigger) do
    format_issue(
      ctx,
      message: "Module attribute names should be written in snake_case.",
      trigger: trigger,
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
