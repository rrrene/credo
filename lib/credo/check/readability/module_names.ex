defmodule Credo.Check.Readability.ModuleNames do
  use Credo.Check,
    id: "EX3010",
    base_priority: :high,
    param_defaults: [
      ignore: []
    ],
    explanations: [
      check: """
      Module names are always written in PascalCase in Elixir.

          # PascalCase

          defmodule MyApp.WebSearchController do
            # ...
          end

          # not PascalCase

          defmodule MyApp.Web_searchController do
            # ...
          end

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of other reading and liking your code by making
      it easier to follow.
      """,
      params: [
        ignore:
          "List of ignored module names and patterns e.g. `[~r/Sample_Module/, \"Credo.Sample_Module\"]`"
      ]
    ]

  alias Credo.Code.Name

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:defmodule, _meta, [{:__aliases__, meta, names} | _]} = ast, ctx) do
    name =
      names
      |> Enum.filter(&String.Chars.impl_for/1)
      |> Enum.join(".")

    module_name = Name.full(name)

    pascal_case? =
      module_name
      |> String.split(".")
      |> Enum.all?(&Name.pascal_case?/1)

    if pascal_case? or ignored_module?(ctx.params.ignore, module_name) do
      {ast, ctx}
    else
      {ast, put_issue(ctx, issue_for(ctx, meta, name))}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta, trigger) do
    format_issue(
      ctx,
      message: "Module names should be written in PascalCase.",
      trigger: trigger,
      line_no: meta[:line],
      column: meta[:column]
    )
  end

  defp ignored_module?([], _module_name), do: false

  defp ignored_module?(ignored_patterns, module_name) do
    Enum.any?(ignored_patterns, fn
      %Regex{} = pattern ->
        String.match?(module_name, pattern)

      name when is_atom(name) ->
        module_name == Credo.Code.Name.full(name)

      name ->
        module_name == name
    end)
  end
end
