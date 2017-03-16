defmodule Credo.Check.ConfigCommentFinder do
  @moduledoc """
  """
  @explanation nil
  @config_comment_format ~r/#\s*credo\:([\w-\:]+)\s*(.*)/

  use Credo.Check, run_on_all: true, base_priority: :high

  alias Credo.SourceFile
  alias Credo.Check.CodeHelper
  alias Credo.Check.ConfigComment

  @doc false
  def run(source_files, _params) when is_list(source_files) do
    Enum.map(source_files, &find_and_set_in_source_file/1)
  end

  def find_and_set_in_source_file(source_file) do
    config_comments = find_config_comments(source_file)

    %SourceFile{source_file | config_comments: config_comments}
  end

  defp find_config_comments(%SourceFile{source: source}) do
    source
    |> CodeHelper.clean_strings_and_sigils
    |> Credo.Code.to_lines
    |> Enum.reduce([], &find_config_comment/2)
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
