defmodule Credo.Check.Readability.SpecParameterNames do
  use Credo.Check,
    id: "EX3037",
    base_priority: :low,
    explanations: [
      check: """
      Parameters in `@spec` and `@callback` declarations should be named.

      Using the `name :: type` syntax, naming parameters makes specs self-documenting:
      readers and ExDoc see what each argument is for, not just its type.
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

  defp walk(
         {:@, _meta,
          [{attr_type, _attr_meta, [{:when, _meta2, [{:"::", _inner_meta, [fun_call, _return_type]} | _guards]}]}]},
         ctx
       )
       when attr_type in [:spec, :callback] do
    {nil, check_fun_call(fun_call, ctx)}
  end

  defp walk({:@, _meta, [{attr_type, _attr_meta, [{:"::", _meta2, [fun_call, _return_type]}]}]}, ctx)
       when attr_type in [:spec, :callback] do
    {nil, check_fun_call(fun_call, ctx)}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp check_fun_call({_fun_name, _meta, args}, ctx) when is_list(args) do
    Enum.reduce(args, ctx, &check_arg/2)
  end

  defp check_fun_call({_fun_name, _meta, nil}, ctx), do: ctx
  defp check_fun_call(_other, ctx), do: ctx

  defp check_arg(args, ctx) when is_list(args) do
    Enum.reduce(args, ctx, &check_arg/2)
  end

  # Named param: `name :: type`
  defp check_arg({:"::", _meta, [{name, _name_meta, nil}, _type]}, ctx) when is_atom(name) do
    ctx
  end

  defp check_arg(nil, ctx) do
    ctx
  end

  defp check_arg({:|, _meta, args}, ctx) when is_list(args) do
    Enum.reduce(args, ctx, &check_arg/2)
  end

  defp check_arg({:->, _meta, [arg, _result]}, ctx) do
    check_arg(arg, ctx)
  end

  defp check_arg({:%{}, _meta, args}, ctx) when is_list(args) do
    ctx
  end

  defp check_arg({_, [_ | _] = _meta, _} = arg, ctx) do
    put_issue(ctx, issue_for(ctx, arg))
  end

  # Keyword param: `with: String.t()`
  defp check_arg({keyword, arg}, ctx) when is_atom(keyword) do
    check_arg(arg, ctx)
  end

  defp check_arg(tuple, ctx) when is_tuple(tuple) do
    Enum.reduce(Tuple.to_list(tuple), ctx, &check_arg/2)
  end

  defp check_arg(_, ctx) do
    ctx
  end

  defp issue_for(ctx, {_, meta, _} = arg) do
    format_issue(
      ctx,
      message: "Spec parameter is missing a name. Use `name :: type` syntax.",
      line_no: meta[:line],
      trigger: Credo.Code.Name.full(arg)
    )
  end
end
