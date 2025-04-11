defmodule Credo.Check.Design.TagHelper do
  @moduledoc false

  @doc_attribute_names [:doc, :moduledoc, :shortdoc]

  alias Credo.SourceFile

  alias Credo.Check.Design.TagHelperDeprecated

  @deprecated "Use find_tags/3 instead"
  def tags(source_file, tag_name, include_doc?) do
    TagHelperDeprecated.tags(source_file, tag_name, include_doc?)
  end

  def find_tags(source_file, tag_name, include_doc?) do
    tags_from_module_attributes(source_file, tag_name, include_doc?) ++
      tags_from_comments_new(source_file, tag_name)
  end

  defp tags_from_module_attributes(source_file, tag_name, true) do
    regex = Regex.compile!("\\A\\s*#{tag_name}:?\\s*.+", "i")

    Credo.Code.prewalk(source_file, &traverse(&1, &2, regex))
  end

  defp tags_from_module_attributes(_source_file, _tag_name, false) do
    []
  end

  defp tags_from_comments_new(source_file, tag_name) do
    regex = Regex.compile!("(\\A|[^\\?])#\\s*#{tag_name}:?\\s*.+", "i")

    {_ast, comments} = SourceFile.ast_with_comments(source_file)

    Enum.reduce(comments, [], &find_tags_in_comments(&1, &2, regex))
  end

  defp find_tags_in_comments(%{text: string} = comment, memo, regex) do
    if string =~ regex do
      trigger =
        regex
        |> Regex.run(string)
        |> List.wrap()
        |> Enum.map(&String.trim/1)
        |> List.first()

      memo ++ [{{comment.line, comment.column}, string, trigger}]
    else
      memo
    end
  end

  defp traverse({:@, at_meta, [{name, meta, [string]} | _]} = ast, memo, regex)
       when name in @doc_attribute_names and is_binary(string) do
    if string =~ regex do
      trimmed = String.trim_trailing(string)
      is_heredoc? = String.match?(string, ~r/\n/)

      location =
        if is_heredoc? do
          {at_meta[:line] + 1, at_meta[:column]}
        else
          # TODO: calculate the column for single line strings
          {meta[:line], nil}
        end

      {nil, memo ++ [{location, trimmed, trimmed}]}
    else
      {ast, memo}
    end
  end

  defp traverse(ast, memo, _regex) do
    {ast, memo}
  end
end
