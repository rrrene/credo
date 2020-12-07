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
          @spec a_function(%MyModule{}) :: any

          # NOT preferred
          @spec a_function(MyModule.t()) :: any
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # `::` and `when` are used in specs
  defp traverse({:spec, meta, [{atom, _, _} | _] = args}, issues, issue_meta)
       when atom in ~w(:: when)a do
    case Macro.prewalk(args, nil, &find_structs/2) do
      {ast, nil} ->
        {ast, issues}

      {ast, struct} ->
        options = [
          message: "Struct %#{struct}{} found in @spec",
          trigger: struct,
          line_no: meta[:line]
        ]

        {ast, [format_issue(issue_meta, options) | issues]}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp find_structs({:%, _, [{:__aliases__, _, modules} | _]} = ast, _acc) do
    {ast, Enum.join(modules, ".")}
  end

  defp find_structs(ast, acc) do
    {ast, acc}
  end
end
