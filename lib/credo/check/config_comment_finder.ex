defmodule Credo.Check.ConfigCommentFinder do
  @moduledoc false

  # This check is used internally by Credo.
  #
  # It traverses the given codebase to find `Credo.Check.ConfigComment`
  # compatible comments, which control Credo's behaviour.

  @config_comment_format ~r/#\s*credo\:([\w-\:]+)\s*(.*)/im

  alias Credo.Check.ConfigComment
  alias Credo.SourceFile

  @doc false
  def run(source_files) when is_list(source_files) do
    source_files
    |> Enum.map(&find_and_set_in_source_file/1)
    |> Enum.reject(&is_nil/1)
  end

  def find_and_set_in_source_file(source_file) do
    case find_config_comments(source_file) do
      [] ->
        nil

      config_comments ->
        {source_file.filename, config_comments}
    end
  end

  defp find_config_comments(source_file) do
    source = SourceFile.source(source_file)

    if source =~ @config_comment_format do
      source
      |> Credo.Code.clean_charlists_strings_and_sigils()
      |> Credo.Code.to_lines()
      |> Enum.reduce([], &find_config_comment/2)
    else
      []
    end
  end

  defp find_config_comment({line_no, string}, memo) do
    case Regex.run(@config_comment_format, string) do
      nil ->
        memo

      [_, instruction, param_string] ->
        memo ++ [ConfigComment.new(instruction, param_string, line_no)]
    end
  end
end
