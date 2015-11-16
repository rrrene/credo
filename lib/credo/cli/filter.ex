defmodule Credo.CLI.Filter do
  alias Credo.Issue
  alias Credo.SourceFile

  def important(list, config) when is_list(list) do
    list
    |> Enum.filter(&important?(&1, config))
  end

  def important?(%Issue{} = issue, config) do
    issue.priority >= config.min_priority
  end
  def important?(%SourceFile{} = source_file, config) do
    source_file.issues
    |> Enum.any?(&important?(&1, config))
  end
end
