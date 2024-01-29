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
    comments = SourceFile.comments(source_file)

    comments
    |> Enum.filter(fn %{text: text} ->
      String.match?(text, regex)
    end)
    |> Enum.map(fn %{line: line_no, text: text} ->
      {line_no, text}
    end)
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
end
