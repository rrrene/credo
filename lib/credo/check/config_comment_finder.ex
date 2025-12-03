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
    source = SourceFile.source(source_file)

    if source =~ config_comment_format() do
      case Code.string_to_quoted_with_comments(source) do
        {:ok, _ast, comments} -> extract_config_comments(comments)
        {:error, _} -> []
      end
    else
      []
    end
  end

  defp extract_config_comments(comments) do
    Enum.flat_map(comments, fn %{text: text, line: line_no} ->
      case Regex.run(config_comment_format(), text) do
        nil -> []
        [_, instruction, param_string] -> [ConfigComment.new(instruction, param_string, line_no)]
      end
    end)
  end

  # moved to private function due to deprecation of regexes
  # in module attributes in Elixir 1.19
  defp config_comment_format, do: ~r/#\s*credo\:([\w\-\:]+)\s*(.*)/im
end
