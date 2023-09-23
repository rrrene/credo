defmodule Credo.Check.Readability.DuplicatedAliases do
  use Credo.Check

  alias Credo.SourceFile

  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    source_ast = SourceFile.ast(source_file)

    {_, {_, _, issues}} = Macro.prewalk(source_ast, {%{}, issue_meta, []}, &traverse(&1, &2))
    issues
  end

  defp traverse(
         {:alias, _, [{:__aliases__, meta, alias_} | _]} = ast,
         {cache, issue_meta, issues}
       ) do
    if Map.has_key?(cache, alias_) do
      existing_alias_meta = Map.fetch!(cache, alias_)
      issue = build_issue(alias_, meta[:line], existing_alias_meta[:line], issue_meta)
      {ast, {cache, issue_meta, [issue | issues]}}
    else
      {ast, {Map.put(cache, alias_, meta), issue_meta, issues}}
    end
  end

  defp traverse(ast, acc), do: {ast, acc}

  defp build_issue(trigger, line_no, existing_alias_line_no, issue_meta) do
    format_issue(
      issue_meta,
      message:
        "Duplicated alias: #{format_alias(trigger)}, already defined in line #{existing_alias_line_no}",
      trigger: "#{format_alias(trigger)}",
      line_no: line_no
    )
  end

  defp format_alias(a) do
    a
    |> List.wrap()
    |> Enum.join(".")
  end
end
