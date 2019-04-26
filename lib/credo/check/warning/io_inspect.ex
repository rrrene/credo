defmodule Credo.Check.Warning.IoInspect do
  @moduledoc false

  @checkdoc """
  While calls to IO.inspect might appear in some parts of production code,
  most calls to this function are added during debugging sessions.

  This check warns about those calls, because they might have been committed
  in error.

  Pass [excluded: [r/regex_pattern/]] as params in your configuration to exclude
  files, like setup scripts, where you expect IO.inspect to be present.

  Example:
  To exclude all `.exs` files you will add this to your `.credo.exs` file:

  `{Credo.Check.Warning.IoInspect, [excluded: [~r/.exs$/]]}`
  """
  @explanation [check: @checkdoc]
  @call_string "IO.inspect"

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    params
    |> Keyword.get(:excluded, [])
    |> match_filename?(source_file.filename)
    |> case do
      true -> []
      _ ->
        issue_meta = IssueMeta.for(source_file, params)
        Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
    end
  end

  defp match_filename?([], _filename), do: false
  defp match_filename?([h|t] = excluded_patterns, filename) when is_list(excluded_patterns) do
    String.match?(filename, h) || match_filename?(t, filename)
  end

  defp traverse(
         {{:., _, [{:__aliases__, _, [:IO]}, :inspect]}, meta, _arguments} = ast,
         issues,
         issue_meta
       ) do
    {ast, issues_for_call(meta, issues, issue_meta)}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issues_for_call(meta, issues, issue_meta) do
    [issue_for(issue_meta, meta[:line], @call_string) | issues]
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "There should be no calls to IO.inspect/1.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
