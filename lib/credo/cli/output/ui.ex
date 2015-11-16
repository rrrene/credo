defmodule Credo.CLI.Output.UI do

  @edge "┃"

  def edge(color, indent \\ 2) when is_integer(indent) do
    [:reset, color, @edge |> String.ljust(indent)]
  end

  defdelegate puts, to: Bunt
  defdelegate puts(v), to: Bunt
  def puts(v, color), do: Bunt.puts([color, v])

end
