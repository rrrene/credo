# Improving Custom Checks

```elixir
defmodule Credo.Check.Readability.DuplicatedAliases do
  use Credo.Check,
    base_priority: :low,
    category: :readability,
    explanations: [
      check: """
      Sometimes during code reviews in large projects with modules that use many
      aliases, there can be issues when solving conflicts and some duplicated
      may end up not being noticed by reviewers and get merged into the main
      branch.

      These duplicated alias can accumulate over many different files over time
      and make the aliases section of a file larger and more confusing.
      """
    ]

  alias Credo.SourceFile

  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    source_ast = SourceFile.ast(source_file)

    {_, {_, _, issues}} = Macro.prewalk(source_ast, {%{}, issue_meta, []}, &traverse(&1, &2))
    issues
  end

  defp traverse(
         {:alias, _, [{:__aliases__, meta, aliased_module} | _]} = ast,
         {cache, issue_meta, issues}
       ) do
    if Map.has_key?(cache, aliased_module) do
      existing_alias_meta = Map.fetch!(cache, aliased_module)
      issue = build_issue(Credo.Code.Name.full(aliased_module), meta[:line], existing_alias_meta[:line], issue_meta)

      {ast, {cache, issue_meta, [issue | issues]}}
    else
      {ast, {Map.put(cache, aliased_module, meta), issue_meta, issues}}
    end
  end

  defp traverse(ast, acc), do: {ast, acc}

  defp build_issue(trigger, line_no, existing_alias_line_no, issue_meta) do
    format_issue(
      issue_meta,
      message:
        "Duplicated alias: #{trigger}, already defined in line #{existing_alias_line_no}",
      trigger: trigger,
      line_no: line_no
    )
  end
end
```
