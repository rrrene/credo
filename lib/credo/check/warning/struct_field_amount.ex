defmodule Credo.Check.Warning.StructFieldAmount do
  use Credo.Check,
    id: "EX5026",
    base_priority: :normal,
    category: :warning,
    param_defaults: [max_fields: 31],
    explanations: [
      check: """
      Avoid structs with 32 or more fields.

      Structs in Elixir are implemented as compile-time maps, which have a
      predefined amount of fields.

      When structs have 32 or more fields, their internal representation in
      the Erlang Virtual Machines changes, potentially leading to bloating
      and higher memory usage.

      https://hexdocs.pm/elixir/1.19.0/code-anti-patterns.html#structs-with-32-fields-or-more
      """,
      params: [
        max_fields: "The maximum number of field a struct should be allowed to have."
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:defstruct, meta, [fields]} = ast, ctx) when is_list(fields) do
    count = length(fields)

    if count > ctx.params.max_fields do
      {ast, put_issue(ctx, issue_for(ctx, meta, count))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta, count) do
    format_issue(ctx,
      message: "Struct has more than #{ctx.params.max_fields} fields (#{count} found).",
      trigger: "defstruct",
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
