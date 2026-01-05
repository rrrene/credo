defmodule Credo.CLI.Filter do
  @moduledoc false

  # TODO: is this the right place for this module?

  alias Credo.Check.ConfigComment
  alias Credo.Execution
  alias Credo.Issue
  alias Credo.SourceFile

  def important(list, %Execution{} = exec) when is_list(list) do
    Enum.filter(list, &important?(&1, exec))
  end

  def important?(%Issue{} = issue, exec) do
    issue.priority >= exec.config.min_priority
  end

  def important?(%SourceFile{filename: filename}, exec) do
    exec
    |> Execution.get_issues(filename)
    |> Enum.any?(&important?(&1, exec))
  end

  def valid_issues(issues, exec) when is_list(issues) do
    Enum.reject(issues, fn issue ->
      ignored_by_config_comment?(issue, exec)
    end)
  end

  def ignored_by_config_comment?(%Issue{} = issue, exec) do
    config_comment_map = Execution.get_private(exec, :config_comment_map)

    case config_comment_map[issue.filename] do
      config_comments when is_list(config_comments) ->
        Enum.any?(config_comments, fn config_comment ->
          ConfigComment.ignores_issue?(config_comment, issue)
        end)

      _ ->
        false
    end
  end
end
