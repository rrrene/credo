defmodule Credo.Check.Warning.SpecWithStruct do
  use Credo.Check,
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

  defp traverse({:@, meta, [{:spec, _, args}]}, issues, issue_meta) do
    case Macro.prewalk(args, [], &find_structs/2) do
      {ast, []} ->
        {ast, issues}

      {ast, structs} ->
        issues =
          Enum.reduce(structs, issues, fn curr, acc ->
            options = [
              message: "Struct %#{curr}{} found in @spec",
              trigger: "%#{curr}{}",
              line_no: meta[:line]
            ]

            [format_issue(issue_meta, options) | acc]
          end)

        {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp find_structs({:%, _, [{:__aliases__, _, _} = aliases | _]} = ast, acc) do
    {ast, [Name.full(aliases) | acc]}
  end

  defp find_structs(ast, acc) do
    {ast, acc}
  end
end
