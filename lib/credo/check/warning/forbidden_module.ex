defmodule Credo.Check.Warning.ForbiddenModule do
  use Credo.Check,
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
        Enum.map(modules, fn {key, value} -> {Name.full(key), value} end)
      else
        Enum.map(modules, fn key -> {Name.full(key), nil} end)
      end

    Credo.Code.prewalk(
      source_file,
      &traverse(&1, &2, modules, IssueMeta.for(source_file, params))
    )
  end

  defp traverse({:__aliases__, meta, modules} = ast, issues, forbidden_modules, issue_meta) do
    module = Name.full(modules)

    issues = put_issue_if_forbidden(issues, issue_meta, meta[:line], module, forbidden_modules)

    {ast, issues}
  end

  defp traverse(
         {:alias, _meta, [{{_, _, [{:__aliases__, _opts, base_alias}, :{}]}, _, aliases}]} = ast,
         issues,
         forbidden_modules,
         issue_meta
       ) do
    modules =
      Enum.map(aliases, fn {:__aliases__, meta, module} ->
        {Name.full([base_alias, module]), meta[:line]}
      end)

    issues =
      Enum.reduce(modules, issues, fn {module, line}, issues ->
        put_issue_if_forbidden(issues, issue_meta, line, module, forbidden_modules)
      end)

    {ast, issues}
  end

  defp traverse(ast, issues, _, _), do: {ast, issues}

  defp put_issue_if_forbidden(issues, issue_meta, line_no, module, forbidden_modules) do
    forbidden_module_names = Enum.map(forbidden_modules, &elem(&1, 0))

    if found_module?(forbidden_module_names, module) do
      [issue_for(issue_meta, line_no, module, forbidden_modules) | issues]
    else
      issues
    end
  end

  defp found_module?(forbidden_module_names, module) do
    Enum.member?(forbidden_module_names, module)
  end

  defp issue_for(issue_meta, line_no, module, forbidden_modules) do
    trigger = Name.full(module)
    message = message(forbidden_modules, module) || "The `#{trigger}` module is not allowed."

    format_issue(
      issue_meta,
      message: message,
      trigger: trigger,
      line_no: line_no
    )
  end

  defp message(forbidden_modules, module) do
    Enum.find_value(forbidden_modules, fn
      {^module, message} -> message
      _ -> nil
    end)
  end
end
