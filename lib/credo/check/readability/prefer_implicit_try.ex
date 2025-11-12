defmodule Credo.Check.Readability.PreferImplicitTry do
  use Credo.Check,
    id: "EX3017",
    base_priority: :low,
    explanations: [
      check: """
      Prefer using an implicit `try` rather than explicit `try` if you try to rescue
      anything the function does.

      For example, this:

          def failing_function(first) do
            try do
              to_string(first)
            rescue
              _ -> :rescued
            end
          end

      Can be rewritten without `try` as below:

          def failing_function(first) do
            to_string(first)
          rescue
            _ -> :rescued
          end

      This emphazises that you really want to try/rescue anything the function does,
      which might be important for other contributors so they can reason about adding
      code to the function.

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @def_ops [:def, :defp, :defmacro]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  for op <- @def_ops do
    defp walk({unquote(op), _, [{_, _, _}, [do: {:try, meta, _}]]} = ast, ctx) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta) do
    format_issue(
      ctx,
      message: "Prefer using an implicit `try` rather than explicit `try`.",
      trigger: "try",
      line_no: meta[:line]
    )
  end
end
