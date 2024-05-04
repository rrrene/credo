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
    forbidden_modules =
      params
      |> Params.get(:modules, __MODULE__)
      |> Enum.map(fn
        {key, value} -> {Name.full(key), value}
        key -> {Name.full(key), nil}
      end)
      |> Map.new()

    Credo.Code.prewalk(
      source_file,
      &traverse(&1, &2, forbidden_modules, IssueMeta.for(source_file, params))
    )
  end

  defp traverse({:__aliases__, meta, modules} = ast, issues, forbidden_modules, issue_meta) do
    module = Name.full(modules)

    issues = put_issue_if_forbidden(issues, issue_meta, meta, module, forbidden_modules, module)

    {ast, issues}
  end

  defp traverse(
         {:alias, _meta, [{{_, _, [{:__aliases__, _opts, base_alias}, :{}]}, _, aliases}]} = ast,
         issues,
         forbidden_modules,
         issue_meta
       ) do
    issues =
      Enum.reduce(aliases, issues, fn {:__aliases__, meta, module}, issues ->
        full_module = Name.full([base_alias, module])
        module = Name.full(module)

        put_issue_if_forbidden(issues, issue_meta, meta, full_module, forbidden_modules, module)
      end)

    {ast, issues}
  end

  defp traverse(ast, issues, _, _), do: {ast, issues}

  defp put_issue_if_forbidden(issues, issue_meta, meta, module, forbidden_modules, trigger) do
    if Map.has_key?(forbidden_modules, module) do
      [issue_for(issue_meta, meta, module, forbidden_modules, trigger) | issues]
    else
      issues
    end
  end

  defp issue_for(issue_meta, meta, module, forbidden_modules, trigger) do
    message = forbidden_modules[module] || "The `#{trigger}` module is not allowed."

    format_issue(
      issue_meta,
      message: message,
      trigger: trigger,
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
