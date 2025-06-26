defmodule Credo.Check.Design.TagHelper do
  @moduledoc false

  @doc_attribute_names [:doc, :moduledoc, :shortdoc]

  alias Credo.SourceFile

  def tags(source_file, tag_name, include_doc?) do
    tags_from_module_attributes(source_file, tag_name, include_doc?) ++
      tags_from_comments(source_file, tag_name)
  end

  defp tags_from_module_attributes(source_file, tag_name, true) do
    regex = Regex.compile!("\\A\\s*#{tag_name}:?\\s*.+", "i")

    Credo.Code.prewalk(source_file, &traverse(&1, &2, regex))
  end

  defp tags_from_module_attributes(_source_file, _tag_name, false) do
    []
  end

  defp tags_from_comments(source_file, tag_name) do
    regex = Regex.compile!("(\\A|[^\\?])#\\s*#{tag_name}:?\\s*.+", "i")
    source = SourceFile.source(source_file)

    if source =~ regex do
      source
      |> Credo.Code.clean_charlists_strings_and_sigils()
      |> String.split("\n")
      |> Enum.with_index()
      |> Enum.map(&find_tag_in_line(&1, regex))
      |> Enum.filter(&tags?/1)
    else
      []
    end
  end

  defp traverse({:@, _, [{name, meta, [string]} | _]} = ast, memo, regex)
       when name in @doc_attribute_names and is_binary(string) do
    if string =~ regex do
      trimmed = String.trim_trailing(string)

      {nil, memo ++ [{meta[:line], trimmed, trimmed}]}
    else
      {ast, memo}
    end
  end

  defp traverse(ast, memo, _regex) do
    {ast, memo}
  end

  defp find_tag_in_line({line, index}, regex) do
    tag_list =
      regex
      |> Regex.run(line)
      |> List.wrap()
      |> Enum.map(&String.trim/1)

    {index + 1, line, List.first(tag_list)}
  end

  defp tags?({_line_no, _line, nil}), do: false
  defp tags?({_line_no, _line, _tag}), do: true
end
