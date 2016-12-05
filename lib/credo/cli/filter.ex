defmodule Credo.CLI.Filter do
  alias Credo.Issue
  alias Credo.SourceFile
  alias Credo.Check.LintAttribute

  def important(list, config) when is_list(list) do
    Enum.filter(list, &important?(&1, config))
  end

  def important?(%Issue{} = issue, config) do
    issue.priority >= config.min_priority
  end
  def important?(%SourceFile{} = source_file, config) do
    Enum.any?(source_file.issues, &important?(&1, config))
  end


  def valid_issues(list, config) when is_list(list) do
    Enum.reject(list, &ignored?(&1, config))
  end

  def ignored?(%Issue{} = issue, config) do
    case config.lint_attribute_map[issue.filename] do
      list when is_list(list) ->
        Enum.any?(list, &(LintAttribute.ignores_issue?(&1, issue)))
      _ ->
        false
    end
  end
end
