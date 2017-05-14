defmodule Credo.CLI.Filter do
  alias Credo.Issue
  alias Credo.SourceFile
  alias Credo.Check.LintAttribute
  alias Credo.Check.ConfigComment

  def important(list, exec) when is_list(list) do
    Enum.filter(list, &important?(&1, exec))
  end

  def important?(%Issue{} = issue, exec) do
    issue.priority >= exec.min_priority
  end
  def important?(%SourceFile{filename: filename}, exec) do
    exec
    |> Credo.Execution.get_issues(filename)
    |> Enum.any?(&important?(&1, exec))
  end

  def valid_issues(list, exec) when is_list(list) do
    Enum.reject(list, fn(issue) ->
      ignored_by_lint_attribute?(issue, exec) ||
        ignored_by_config_comment?(issue, exec)
    end)
  end

  def ignored_by_lint_attribute?(%Issue{} = issue, exec) do
    case exec.lint_attribute_map[issue.filename] do
      list when is_list(list) ->
        Enum.any?(list, &(LintAttribute.ignores_issue?(&1, issue)))
      _ ->
        false
    end
  end

  def ignored_by_config_comment?(%Issue{} = issue, exec) do
    case exec.config_comment_map[issue.filename] do
      list when is_list(list) ->
        Enum.any?(list, &(ConfigComment.ignores_issue?(&1, issue)))
      _ ->
        false
    end
  end
end
