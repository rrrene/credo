defmodule Credo.Check.Warning.RaiseInsideRescue do
  use Credo.Check,
    explanations: [
      check: """
      Using `Kernel.raise` inside of a `rescue` block creates a new stacktrace.

      Most of the time, this is not what you want to do since it obscures the cause of the original error.

      Example:

          # preferred

          try do
            raise "oops"
          rescue
            error ->
              Logger.warn("An exception has occurred")

              reraise error, System.stacktrace
          end

          # NOT preferred

          try do
            raise "oops"
          rescue
            error ->
              Logger.warn("An exception has occurred")

              raise error
          end
      """
    ]

  alias Credo.Code.Block

  @def_ops [:def, :defp, :defmacro, :defmacrop]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # TODO: consider for experimental check front-loader (ast)
  defp traverse({:try, _meta, _arguments} = ast, issues, issue_meta) do
    case Block.rescue_block_for(ast) do
      {:ok, ast} ->
        issues_found = Credo.Code.prewalk(ast, &find_issues(&1, &2, issue_meta))

        {ast, issues ++ issues_found}

      _ ->
        {ast, issues}
    end
  end

  defp traverse(
         {op, _meta, [_def, [do: _do, rescue: rescue_block]]},
         issues,
         issue_meta
       )
       when op in @def_ops do
    issues_found = Credo.Code.prewalk(rescue_block, &find_issues(&1, &2, issue_meta))

    {rescue_block, issues ++ issues_found}
  end

  defp traverse(ast, issues, _issue_meta), do: {ast, issues}

  defp find_issues({:raise, meta, _arguments} = ast, issues, issue_meta) do
    issue = issue_for(issue_meta, meta[:line])

    {ast, issues ++ [issue]}
  end

  defp find_issues(ast, issues, _), do: {ast, issues}

  defp issue_for(issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "Use `reraise` inside a rescue block to preserve the original stacktrace.",
      trigger: "raise",
      line_no: line_no
    )
  end
end
