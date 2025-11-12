defmodule Credo.Check.Warning.SpecWithStruct do
  use Credo.Check,
    id: "EX5014",
    base_priority: :normal,
    category: :warning,
    explanations: [
      check: """
      Structs create compile-time dependencies between modules.  Using a struct in a spec
      will cause the module to be recompiled whenever the struct's module changes.

      It is preferable to define and use `MyModule.t()` instead of `%MyModule{}` in specs.

      Example:

          # preferred
          @spec a_function(MyModule.t()) :: any

          # NOT preferred
          @spec a_function(%MyModule{}) :: any
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

  defp walk({:@, _, [{:spec, _, args}]}, ctx) do
    case Macro.prewalk(args, [], &find_structs/2) do
      {ast, []} ->
        {ast, ctx}

      {ast, structs} ->
        issues =
          Enum.reduce(structs, [], fn {curr, meta}, acc ->
            [issue_for(ctx, meta, curr) | acc]
          end)

        {ast, put_issue(ctx, issues)}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp find_structs({:%, meta, [{:__aliases__, _, _} = aliases | _]} = ast, acc) do
    {ast, [{Name.full(aliases), meta} | acc]}
  end

  defp find_structs(ast, acc) do
    {ast, acc}
  end

  defp issue_for(ctx, meta, struct) do
    format_issue(ctx,
      message: "Struct %#{struct}{} found in `@spec`.",
      trigger: "%#{struct}{",
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
