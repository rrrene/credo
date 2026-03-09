defmodule Credo.Check.Warning.ForbiddenModule do
  use Credo.Check,
    id: "EX5004",
    base_priority: :high,
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
    ctx = Context.build(source_file, params, __MODULE__)
    ctx = put_param(ctx, :modules, prepare_modules(ctx.params.modules))
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:__aliases__, meta, modules} = ast, ctx) do
    module = Name.full(modules)

    issue = issue_if_forbidden(ctx, meta, module, module)

    {ast, put_issue(ctx, issue)}
  end

  defp walk(
         {:alias, _meta, [{{_, _, [{:__aliases__, _opts, base_alias}, :{}]}, _, aliases}]} = ast,
         ctx
       ) do
    issues =
      Enum.reduce(aliases, [], fn {:__aliases__, meta, module}, issues ->
        full_module = Name.full([base_alias, module])
        module = Name.full(module)

        if issue = issue_if_forbidden(ctx, meta, full_module, module) do
          [issue | issues]
        else
          issues
        end
      end)

    {ast, put_issue(ctx, issues)}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp issue_if_forbidden(ctx, meta, module, trigger) do
    if Map.has_key?(ctx.params.modules, module) do
      issue_for(ctx, meta, module, trigger)
    end
  end

  defp prepare_modules(modules) do
    modules
    |> Enum.map(fn
      {module, message} -> {Name.full(module), message}
      module -> {Name.full(module), nil}
    end)
    |> Map.new()
  end

  defp issue_for(ctx, meta, module, trigger) do
    message = ctx.params.modules[module] || "The `#{trigger}` module is not allowed."

    format_issue(
      ctx,
      message: message,
      trigger: trigger,
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
