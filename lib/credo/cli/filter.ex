defmodule Credo.CLI.Filter do
  @moduledoc false

  # TODO: is this the right place for this module?

  alias Credo.Check.ConfigComment
  alias Credo.Execution
  alias Credo.Issue
  alias Credo.SourceFile

  def important(list, exec) when is_list(list) do
    Enum.filter(list, &important?(&1, exec))
  end

  def important?(%Issue{} = issue, exec) do
    issue.priority >= exec.min_priority
  end

  def important?(%SourceFile{filename: filename}, exec) do
    exec
    |> Execution.get_issues(filename)
    |> Enum.any?(&important?(&1, exec))
  end

  def valid_issues(list, exec) when is_list(list) do
    Enum.reject(list, fn issue ->
      ignored_by_config_comment?(issue, exec)
    end)
  end

  def ignored_by_config_comment?(%Issue{} = issue, exec) do
    case exec.config_comment_map[issue.filename] do
      list when is_list(list) ->
        Enum.any?(list, &ConfigComment.ignores_issue?(&1, issue))

      _ ->
        false
    end
  end
end
