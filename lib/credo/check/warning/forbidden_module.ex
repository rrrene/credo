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
        modules: "List of Modules or {Module, \"Error message\"} Tuples that must not be used."
      ]
    ]

  alias Credo.Code

  @impl Credo.Check
  def run(source_file = %SourceFile{}, params) do
    modules = Params.get(params, :modules, __MODULE__)

    Code.prewalk(source_file, &traverse(&1, &2, modules, IssueMeta.for(source_file, params)))
  end

  defp traverse(ast = {:__aliases__, meta, modules}, issues, modules_param, issue_meta) do
    module = Module.concat(modules)

    forbidden_modules =
      if Keyword.keyword?(modules_param), do: Keyword.keys(modules_param), else: modules_param

    if found_module?(forbidden_modules, module) do
      {ast, [issue_for(issue_meta, meta[:line], module, modules_param) | issues]}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _, _), do: {ast, issues}

  defp found_module?(forbidden_modules, module)
       when is_list(forbidden_modules) and is_atom(module) do
    Enum.member?(forbidden_modules, module)
  end

  defp found_module?(_, _), do: false

  defp issue_for(issue_meta, line_no, module, modules_param) do
    trigger = module |> Code.Module.name()

    format_issue(
      issue_meta,
      message: message(modules_param, module, "The `#{trigger}` module is not allowed."),
      trigger: trigger,
      line_no: line_no
    )
  end

  defp message(modules_param, module, default) do
    with true <- Keyword.keyword?(modules_param),
         value when not is_nil(value) <- Keyword.get(modules_param, module) do
      value
    else
      _ -> default
    end
  end
end
