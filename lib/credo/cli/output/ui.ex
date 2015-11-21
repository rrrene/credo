defmodule Credo.CLI.Output.UI do

  @edge "┃"

  def edge(color, indent \\ 2) when is_integer(indent) do
    [:reset, color, @edge |> String.ljust(indent)]
  end

  defdelegate puts, to: Bunt
  defdelegate puts(v), to: Bunt
  def puts(v, color), do: Bunt.puts([color, v])


  def wrap_at(text, number, acc \\ []) do
    Regex.compile!("(?:((?>.{1,#{number}}(?:(?<=[^\\S\\r\\n])[^\\S\\r\\n]?|(?=\\r?\\n)|$|[^\\S\\r\\n]))|.{1,#{number}})(?:\\r?\\n)?|(?:\\r?\\n|$))")
    |> Regex.scan(text)
    |> Enum.map(&List.first/1)
    |> List.delete_at(-1) 
  end
end
