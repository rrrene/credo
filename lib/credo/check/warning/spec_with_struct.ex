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
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:@, _, [{:spec, _, args}]}, issues, issue_meta) do
    case Macro.prewalk(args, [], &find_structs/2) do
      {ast, []} ->
        {ast, issues}

      {ast, structs} ->
        issues =
          Enum.reduce(structs, issues, fn {curr, meta}, acc ->
            [issue_for(issue_meta, meta, curr) | acc]
          end)

        {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp find_structs({:%, meta, [{:__aliases__, _, _} = aliases | _]} = ast, acc) do
    {ast, [{Name.full(aliases), meta} | acc]}
  end

  defp find_structs(ast, acc) do
    {ast, acc}
  end

  defp issue_for(issue_meta, meta, struct) do
    format_issue(issue_meta,
      message: "Struct %#{struct}{} found in `@spec`.",
      trigger: "%#{struct}{",
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
