defmodule Credo.Check.Readability.CaptureOperator do
  use Credo.Check,
    id: "EX3099",
    tags: [],
    param_defaults: [
      allow_field_access: false,
      allow_function_with_arity: false
    ],
    explanations: [
      check: """
      Using the capture operator can be a powerful short-hand, but sometimes this
      makes the code more difficult to read.

          # preferred

          permissions = Enum.map(users, fn user -> {user.username, user.allowed?} end)

          # NOT preferred

          permissions = Enum.map(users, &{&1.username, &1.allowed?})

      While veterans understand the first snippet easily, folks new to the language or team
      might have a better chance at grapsing what is happening.

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """,
      params: [
        allow_field_access: "Allow very short captures only accessing a field using `& &1.foo` or `& &1[:foo]`.",
        allow_function_with_arity: "Allow plain captures of functions using their arity `&String.downcase/1`."
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:=, _, [_, {:&, _, [_ | _]}]}, ctx) do
    {nil, ctx}
  end

  # & &1.foo
  defp walk(
         {:&, _, [{{:., _, [{:&, _, [1]}, _field]}, _, []}]},
         %{params: %{allow_field_access: true}} = ctx
       ) do
    {nil, ctx}
  end

  # & &1[:foo]
  defp walk(
         {:&, _,
          [
            {{:., _, [Access, :get]}, _, [{:&, _, [_]}, _]}
          ]},
         %{params: %{allow_field_access: true}} = ctx
       ) do
    {nil, ctx}
  end

  # &foo/1
  defp walk(
         {:&, _, [{:/, _, [{{:., _, _}, _, []}, 1]}]},
         %{params: %{allow_function_with_arity: true}} = ctx
       ) do
    {nil, ctx}
  end

  defp walk({:&, meta, [{{:., _, [{:&, _, [1]}, _field]}, _, []}]}, ctx) do
    {nil, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk({:&, meta, [_ | _]}, ctx) do
    {nil, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta) do
    format_issue(
      IssueMeta.for(ctx.source_file, ctx.params),
      message: "Use an anonymous function instead of the capture operator.",
      trigger: "&",
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
