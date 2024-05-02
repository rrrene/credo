defmodule Credo.Check.Warning.ForbiddenModule do
  use Credo.Check,
    id: "EX5004",
    base_priority: :high,
    category: :warning,
    param_defaults: [modules: []],
    explanations: [
      check: """
      Some modules that are included by a package may be hazardous
      if used by your application. Use this check to allow these modules in
      your dependencies but forbid them to be used in your application.

      Examples:

      The `:ecto_sql` package includes the `Ecto.Adapters.SQL` module,
      but direct usage of the `Ecto.Adapters.SQL.query/4` function, and related functions, may
      cause issues when using Ecto's dynamic repositories.
      """,
      params: [
        modules: "List of modules or `{Module, \"Error message\"}` tuples that must not be used."
      ]
    ]

  alias Credo.Code.Name

  @impl Credo.Check
  def run(%SourceFile{} = source_file, params) do
    modules = Params.get(params, :modules, __MODULE__)

    modules =
      if Keyword.keyword?(modules) do
        Map.new(modules, fn {key, value} -> {Name.full(key), value} end)
      else
        Map.new(modules, fn module ->
          full = Name.full(module)
          {full, "The `#{Name.full(module)}` module is not allowed."}
        end)
      end

    Credo.Code.prewalk(
      source_file,
      &traverse(&1, &2, modules, IssueMeta.for(source_file, params))
    )
  end

  defp traverse({:__aliases__, meta, modules} = ast, issues, forbidden_modules, issue_meta) do
    module = Name.full(modules)

    if found_module?(module, forbidden_modules) do
      {ast, [issue_for(issue_meta, meta, module, forbidden_modules[module]) | issues]}
    else
      {ast, issues}
    end
  end

  defp traverse(
         {:alias, _meta, [{{_, _, [{:__aliases__, _opts, base_alias}, :{}]}, _, aliases}]} = ast,
         issues,
         forbidden_modules,
         issue_meta
       ) do
    issues =
      Enum.reduce(aliases, issues, fn {:__aliases__, meta, module}, issues ->
        full_name = Name.full([base_alias, module])

        if found_module?(full_name, forbidden_modules) do
          message = forbidden_modules[full_name]
          trigger = Name.full(module)
          [issue_for(issue_meta, meta, trigger, message) | issues]
        else
          issues
        end
      end)

    {ast, issues}
  end

  defp traverse(ast, issues, _, _), do: {ast, issues}

  defp found_module?(module, forbidden_modules) when is_map_key(forbidden_modules, module),
    do: true

  defp found_module?(_, _), do: false

  defp issue_for(issue_meta, meta, trigger, message) do
    format_issue(
      issue_meta,
      message: message,
      trigger: trigger,
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
