defmodule Credo.Check.Design.TagHelper do
  @explanation ""

  alias Credo.Check.CodeHelper

  def tags(source, tag_name) do
    {:ok, regex} = Regex.compile("[^\?]# #{tag_name}:? .+", "i")

    source
    |> CodeHelper.clean_strings_and_sigils
    |> String.split("\n")
    |> Enum.with_index
    |> Enum.map(&find_tag(&1, regex))
    |> Enum.filter(&tags?/1)
  end

  defp find_tag({line, index}, regex) do
    tag_list =
      regex
      |> Regex.run(line)
      |> List.wrap
      |> Enum.map(&String.strip/1)

    {index + 1, line, tag_list |> List.first}
  end

  defp tags?({_line_no, _line, nil}), do: false
  defp tags?({_line_no, _line, _tag}), do: true

end
