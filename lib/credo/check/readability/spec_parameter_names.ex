defmodule Credo.Check.Readability.SpecParameterNames do
  use Credo.Check,
    id: "EX3037",
    base_priority: :low,
    explanations: [
      check: """
      Parameters in `@spec` and `@callback` declarations should be named using
      the `name :: type` syntax. Naming parameters makes specs self-documenting:
      readers and ExDoc output see what each argument is for, not just its type.
      This is especially valuable when several parameters share the same type.

          # preferred

          @spec create_user(attrs :: map(), email :: String.t()) :: {:ok, User.t()}

          @callback handle_event(event :: String.t(), params :: map(), socket :: Socket.t()) ::
                      {:noreply, Socket.t()}

          # NOT preferred

          @spec create_user(map(), String.t()) :: {:ok, User.t()}

          @callback handle_event(String.t(), map(), Socket.t()) :: {:noreply, Socket.t()}

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:@, _meta, [{attr_type, _attr_meta, [spec_ast]}]} = ast, ctx)
       when attr_type in [:spec, :callback] do
    {ast, check_spec(spec_ast, ctx)}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  # Guard-style spec: `@spec foo(args) :: return when ...`
  defp check_spec(
         {:when, _meta, [{:"::", _inner_meta, [fun_call, _return_type]} | _guards]},
         ctx
       ) do
    check_fun_args(fun_call, ctx)
  end

  # Regular spec: `@spec foo(args) :: return`
  defp check_spec({:"::", _meta, [fun_call, _return_type]}, ctx) do
    check_fun_args(fun_call, ctx)
  end

  defp check_spec(_other, ctx), do: ctx

  defp check_fun_args({_fun_name, _meta, args}, ctx) when is_list(args) do
    Enum.reduce(args, ctx, &check_arg/2)
  end

  defp check_fun_args({_fun_name, _meta, nil}, ctx), do: ctx
  defp check_fun_args(_other, ctx), do: ctx

  # Named param: `name :: type` where name is an atom variable (nil context)
  defp check_arg({:"::", _meta, [{name, _name_meta, nil}, _type]}, ctx)
       when is_atom(name) do
    ctx
  end

  defp check_arg(arg, ctx) do
    put_issue(ctx, issue_for(ctx, arg))
  end

  defp issue_for(ctx, arg) do
    format_issue(
      ctx,
      message: "Spec parameter is missing a name. Use `name :: type` syntax.",
      trigger: trigger_for(arg),
      line_no: line_for(arg)
    )
  end

  defp line_for({_name, meta, _arg_list}) when is_list(meta), do: meta[:line]

  defp line_for({{:., meta, _dot_args}, _call_meta, _call_args}) when is_list(meta),
    do: meta[:line]

  defp line_for(_other), do: nil

  defp trigger_for(
         {{:., _dot_meta, [{:__aliases__, _alias_meta, aliases}, fun]}, _call_meta, _call_args}
       ),
       do: Enum.map_join(aliases, ".", &to_string/1) <> ".#{fun}"

  defp trigger_for({name, _meta, _args}) when is_atom(name), do: to_string(name)
  defp trigger_for(_other), do: "?"
end
