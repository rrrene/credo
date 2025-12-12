defmodule Credo.Check.Readability.Specs do
  use Credo.Check,
    id: "EX3025",
    tags: [:controversial],
    param_defaults: [
      include_defp: false
    ],
    explanations: [
      check: """
      Functions, callbacks and macros need typespecs.

      Adding typespecs gives tools like Dialyzer more information when performing
      checks for type errors in function calls and definitions.

          @spec add(integer, integer) :: integer
          def add(a, b), do: a + b

      Functions with multiple arities need to have a spec defined for each arity:

          @spec foo(integer) :: boolean
          @spec foo(integer, integer) :: boolean
          def foo(a), do: a > 0
          def foo(a, b), do: a > b

      The check only considers whether the specification is present, it doesn't
      perform any actual type checking.

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """,
      params: [
        include_defp: "Include private functions."
      ]
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    specs = Credo.Code.prewalk(source_file, &find_specs(&1, &2))

    ctx = Context.build(source_file, params, __MODULE__, %{specs: specs})
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp find_specs(
         {:spec, _, [{:when, _, [{:"::", _, [{name, _, args}, _]}, _]} | _]} = ast,
         specs
       ) do
    {ast, [{name, length(args)} | specs]}
  end

  defp find_specs({:spec, _, [{_, _, [{name, _, args} | _]}]} = ast, specs)
       when is_list(args) or is_nil(args) do
    args = with nil <- args, do: []
    {ast, [{name, length(args)} | specs]}
  end

  defp find_specs({:impl, _, [impl]} = ast, specs) when impl != false do
    {ast, [:impl | specs]}
  end

  defp find_specs({keyword, meta, [{:when, _, def_ast} | _]}, [:impl | specs])
       when keyword in [:def, :defp] do
    find_specs({keyword, meta, def_ast}, [:impl | specs])
  end

  defp find_specs({keyword, _, [{name, _, nil}, _]} = ast, [:impl | specs])
       when keyword in [:def, :defp] do
    {ast, [{name, 0} | specs]}
  end

  defp find_specs({keyword, _, [{name, _, args}, _]} = ast, [:impl | specs])
       when keyword in [:def, :defp] do
    {ast, [{name, length(args)} | specs]}
  end

  defp find_specs(ast, issues) do
    {ast, issues}
  end

  defp walk({:quote, _, _}, ctx) do
    {nil, ctx}
  end

  defp walk({keyword, meta, [{:when, _, def_ast} | _]}, ctx) when keyword in [:def, :defp] do
    walk({keyword, meta, def_ast}, ctx)
  end

  defp walk({:defp, _, [{_, _, _} | _]} = ast, %{params: %{include_defp: false}} = ctx) do
    {ast, ctx}
  end

  defp walk({keyword, meta, [{name, _, args} | _]} = ast, ctx)
       when keyword in [:def, :defp] and (is_list(args) or is_nil(args)) do
    args = with nil <- args, do: []
    has_spec? = {name, length(args)} in ctx.specs

    if has_spec? do
      {ast, ctx}
    else
      {ast, put_issue(ctx, issue_for(ctx, meta, name))}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta, trigger) when is_tuple(trigger) do
    issue_for(ctx, meta, Macro.to_string(trigger))
  end

  defp issue_for(ctx, meta, trigger) do
    format_issue(
      ctx,
      message: "Functions should have a @spec type specification.",
      trigger: trigger,
      line_no: meta[:line]
    )
  end
end
