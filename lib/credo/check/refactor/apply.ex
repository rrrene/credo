defmodule Credo.Check.Refactor.Apply do
  use Credo.Check,
    id: "EX4003",
    base_priority: :low,
    explanations: [
      check: """
      Prefer calling functions directly if the number of arguments is known
      at compile time instead of using `apply/2` and `apply/3`.

      Example:

          # preferred

          fun.(arg_1, arg_2, ..., arg_n)

          module.function(arg_1, arg_2, ..., arg_n)

          # NOT preferred

          apply(fun, [arg_1, arg_2, ..., arg_n])

          apply(module, :function, [arg_1, arg_2, ..., arg_n])
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:@, _, [{:spec, _, _}]}, ctx) do
    {nil, ctx}
  end

  defp walk({:apply, _meta, [{:__MODULE__, _, _}, _fun, _args]} = ast, ctx) do
    {ast, ctx}
  end

  defp walk(ast, ctx) do
    case issue(ast, ctx) do
      :stop ->
        {nil, ctx}

      nil ->
        {ast, ctx}

      issue ->
        {ast, put_issue(ctx, issue)}
    end
  end

  defp issue({:|>, meta, [{_, _, _} = arg0, {:apply, _, apply_args}]}, ctx) do
    issue({:apply, meta, [arg0 | apply_args]}, ctx) || :stop
  end

  defp issue({:apply, meta, [fun, args]}, ctx) do
    issue(:apply2, fun, args, meta, ctx)
  end

  defp issue({:apply, meta, [_module, fun, args]}, ctx) do
    issue(:apply3, fun, args, meta, ctx)
  end

  defp issue(_ast, _ctx), do: nil

  defp issue(tag, fun, args, meta, ctx) do
    args = if(is_list(args), do: Enum.reverse(args), else: args)

    do_issue(tag, fun, args, meta, ctx)
  end

  defp do_issue(_apply, _fun, [{:|, _, _} | _], _meta, _ctx), do: nil

  defp do_issue(:apply2, {name, _meta, nil}, args, meta, ctx)
       when is_atom(name) and is_list(args) do
    issue_for(meta, ctx)
  end

  defp do_issue(:apply3, fun, args, meta, ctx) when is_atom(fun) and is_list(args) do
    issue_for(meta, ctx)
  end

  defp do_issue(_apply, _fun, _args, _meta, _ctx), do: nil

  defp issue_for(meta, ctx) do
    format_issue(
      ctx,
      message: "Avoid `apply/2` and `apply/3` when the number of arguments is known.",
      trigger: "apply",
      line_no: meta[:line]
    )
  end
end
