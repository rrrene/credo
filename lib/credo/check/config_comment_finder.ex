defmodule Credo.Check.ConfigCommentFinder do
  @moduledoc false

  # This check is used internally by Credo.
  #
  # It traverses the given codebase to find `Credo.Check.ConfigComment`
  # compatible comments, which control Credo's behaviour.

  alias Credo.Check.ConfigComment
  alias Credo.SourceFile

  @doc false
  def run(source_files) when is_list(source_files) do
    source_files
    |> Task.async_stream(&find_and_set_in_source_file/1, ordered: false, timeout: :infinity)
    |> Enum.map(fn {:ok, value} -> value end)
    |> Enum.reject(&is_nil/1)
  end

  def find_and_set_in_source_file(%Credo.SourceFile{status: :valid} = source_file) do
    case find_config_comments(source_file) do
      [] -> nil
      config_comments -> {source_file.filename, config_comments}
    end
  end

  def find_and_set_in_source_file(_), do: nil

  defp find_config_comments(source_file) do
    {_ast, comments} = SourceFile.ast_with_comments(source_file)

    Enum.reduce(comments, [], &find_config_comment/2)
  end

  defp find_config_comment(%{line: line_no, text: string}, memo) do
    config_comment_format = ~r/#\s*credo\:([\w\-\:]+)\s*(.*)/im

    case Regex.run(config_comment_format, string) do
      nil ->
        memo

      [_, instruction, param_string] ->
        memo ++ [ConfigComment.new(instruction, param_string, line_no)]
    end
  end
end
