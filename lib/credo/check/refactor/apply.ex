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

  defp issue({:apply, meta, [_fun, args]}, issue_meta) when is_list(args),
    do: issue_for(issue_meta, meta[:line])

  defp issue({:apply, _meta, [_module, {atom, _meta2, nil}, args]}, _issue_meta)
       when is_atom(atom) and is_list(args),
       do: nil

  defp issue({:apply, meta, [_module, _fun, args]}, issue_meta) when is_list(args),
    do: issue_for(issue_meta, meta[:line])

  defp issue(_ast, _issue_meta), do: nil

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "Avoid `apply/2` and `apply/3` when the number of arguments is known",
      line_no: line_no
    )
  end
end
