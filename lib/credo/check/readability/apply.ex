defmodule Credo.Check.Readability.Apply do
  use Credo.Check,
    base_priority: :low,
    explanations: [
      check: """
      If the number of arguments and the function name are known at compile time,
      prefer `module.function(arg_1, arg_2, ..., arg_n)` as it is clearer than
      `apply(module, :function, [arg_1, arg_2, ..., arg_n])`.
      """
    ]

  alias Credo.Code

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    Code.prewalk(source_file, &traverse(&1, &2, IssueMeta.for(source_file, params)))
  end

  defp traverse(ast, issues, issue_meta) do
    case issue(ast, issue_meta) do
      nil -> {ast, issues}
      issue -> {ast, [issue | issues]}
    end
  end

  defp issue({:apply, meta, [_fun, args]}, issue_meta) when is_list(args),
    do: issue_for(issue_meta, meta[:line])

  defp issue({:apply, meta, [_module, _fun, args]}, issue_meta) when is_list(args),
    do: issue_for(issue_meta, meta[:line])

  defp issue(_ast, _issue_meta), do: nil

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "Avoid apply when the number of arguments is known",
      line_no: line_no
    )
  end
end
