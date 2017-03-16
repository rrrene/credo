defmodule Credo.CLI.Filter do
  alias Credo.Issue
  alias Credo.SourceFile
  alias Credo.Check.LintAttribute
  alias Credo.Check.ConfigComment

  def important(list, config) when is_list(list) do
    Enum.filter(list, &important?(&1, config))
  end

  def important?(%Issue{} = issue, config) do
    issue.priority >= config.min_priority
  end
  def important?(%SourceFile{filename: filename}, config) do
    config
    |> Credo.Config.get_issues(filename)
    |> Enum.any?(&important?(&1, config))
  end

  def valid_issues(list, config) when is_list(list) do
    Enum.reject(list, fn(issue) ->
      ignored_by_lint_attribute?(issue, config) ||
        ignored_by_config_comment?(issue, config)
    end)
  end

  def ignored_by_lint_attribute?(%Issue{} = issue, config) do
    case config.lint_attribute_map[issue.filename] do
      list when is_list(list) ->
        Enum.any?(list, &(LintAttribute.ignores_issue?(&1, issue)))
      _ ->
        false
    end
  end

  def ignored_by_config_comment?(%Issue{} = issue, config) do
    case config.config_comment_map[issue.filename] do
      list when is_list(list) ->
        Enum.any?(list, &(ConfigComment.ignores_issue?(&1, issue)))
      _ ->
        false
    end
  end
end
