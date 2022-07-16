defmodule Credo.Check.Refactor.Apply do
  use Credo.Check,
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
    Credo.Code.prewalk(source_file, &traverse(&1, &2, IssueMeta.for(source_file, params)))
  end

  defp traverse(ast, issues, issue_meta) do
    case issue(ast, issue_meta) do
      nil -> {ast, issues}
      issue -> {ast, [issue | issues]}
    end
  end

  defp issue({:apply, _meta, [{:__MODULE__, _, _}, _fun, _args]}, _issue_meta), do: nil

  defp issue({:apply, meta, [fun, args]}, issue_meta) do
    do_issue(:apply2, fun, args, meta, issue_meta)
  end

  defp issue({:apply, meta, [_module, fun, args]}, issue_meta) do
    do_issue(:apply3, fun, args, meta, issue_meta)
  end

  defp issue(_ast, _issue_meta), do: nil

  defp do_issue(_apply, _fun, [{:|, _, _}], _meta, _issue_meta), do: nil

  defp do_issue(:apply2, {name, _meta, nil}, args, meta, issue_meta)
       when is_atom(name) and is_list(args) do
    issue_for(meta, issue_meta)
  end

  defp do_issue(:apply3, fun, args, meta, issue_meta)
       when is_atom(fun) and is_list(args) do
    issue_for(meta, issue_meta)
  end

  defp do_issue(_apply, _fun, _args, _meta, _issue_meta), do: nil

  defp issue_for(meta, issue_meta) do
    format_issue(
      issue_meta,
      message: "Avoid `apply/2` and `apply/3` when the number of arguments is known",
      line_no: meta[:line]
    )
  end
end
