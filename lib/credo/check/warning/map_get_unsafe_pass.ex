defmodule Credo.Check.Warning.MapGetUnsafePass do
  use Credo.Check,
    id: "EX5009",
    base_priority: :normal,
    tags: [:controversial],
    explanations: [
      check: """
      `Map.get/2` can lead into runtime errors if the result is passed into a pipe
      without a proper default value. This happens when the next function in the
      pipe cannot handle `nil` values correctly.

      Example:

          %{foo: [1, 2 ,3], bar: [4, 5, 6]}
          |> Map.get(:missing_key)
          |> Enum.each(&IO.puts/1)

      This will cause a `Protocol.UndefinedError`, since `nil` isn't `Enumerable`.
      Often times while iterating over enumerables zero iterations is preferable
      to being forced to deal with an exception. Had there been a `[]` default
      parameter this could have been averted.

      If you are sure the value exists and can't be nil, please use `Map.fetch!/2`.
      If you are not sure, `Map.get/3` can help you provide a safe default value.
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
         {:|>, _,
          [
            {:|>, _,
             [
               _pipe_start,
               {{:., _, [{:__aliases__, meta, [:Map]}, :get]}, _, [_single]}
             ]},
            {{:., _, [{:__aliases__, _, [:Enum]}, _enum_fun]}, _, _enum_args}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(
         {:|>, _,
          [
            {{:., _, [{:__aliases__, meta, [:Map]}, :get]}, _, [_first, _second]},
            {{:., _, [{:__aliases__, _, [:Enum]}, _enum_fun]}, _, _enum_args}
          ]} = ast,
         ctx
       ) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta) do
    format_issue(
      ctx,
      message:
        "`Map.get` with no default return value is potentially unsafe in pipes, use `Map.get/3` instead.",
      trigger: "Map.get",
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
