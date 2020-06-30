defmodule Credo.Check.Readability.PreferImplicitTry do
  use Credo.Check,
    base_priority: :low,
    explanations: [
      check: """
      Prefer using an implicit `try` rather than explicit `try` if you try to rescue
      anything the function does.

      For example, this:

          def failing_function(first) do
            try do
              to_string(first)
            rescue
              _ -> :rescued
            end
          end

      Can be rewritten without `try` as below:

          def failing_function(first) do
            to_string(first)
          rescue
            _ -> :rescued
          end

      Like all `Readability` issues, this one is not a technical concern.
      The code will behave identical in both ways.
      """
    ]

  @def_ops [:def, :defp, :defmacro]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # TODO: consider for experimental check front-loader (ast)
  for op <- @def_ops do
    defp traverse(
           {unquote(op), _, [{_, _, _}, [do: {:try, meta, _}]]} = ast,
           issues,
           issue_meta
         ) do
      line_no = meta[:line]

      {ast, issues ++ [issue_for(issue_meta, line_no)]}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "Prefer using an implicit `try` rather than explicit `try`.",
      trigger: "try",
      line_no: line_no
    )
  end
end
