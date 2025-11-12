defmodule Credo.Check.Refactor.FunctionArity do
  use Credo.Check,
    id: "EX4010",
    param_defaults: [max_arity: 8, ignore_defp: false],
    explanations: [
      check: """
      A function can take as many parameters as needed, but even in a functional
      language there can be too many parameters.

      Can optionally ignore private functions (check configuration options).
      """,
      params: [
        max_arity: "The maximum number of parameters which a function should take.",
        ignore_defp: "Set to `true` to ignore private functions."
      ]
    ]

  alias Credo.Code.Parameters

  @def_ops [:def, :defp, :defmacro]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:defp, _, _} = ast, %{params: %{ignore_defp: true}} = ctx) do
    {ast, ctx}
  end

  defp walk({op, meta, arguments} = ast, ctx) when op in @def_ops and is_list(arguments) do
    arity = Parameters.count(ast)

    if arity > ctx.params.max_arity do
      fun_name = Credo.Code.Module.def_name(ast)

      {ast, put_issue(ctx, issue_for(ctx, meta, fun_name, ctx.params.max_arity, arity))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(issue_meta, meta, trigger, max_value, actual_value) do
    format_issue(
      issue_meta,
      message:
        "Function takes too many parameters (arity is #{actual_value}, max is #{max_value}).",
      trigger: trigger,
      line_no: meta[:line],
      severity: Severity.compute(actual_value, max_value)
    )
  end
end
