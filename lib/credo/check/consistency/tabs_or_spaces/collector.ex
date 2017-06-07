defmodule Credo.Check.Consistency.TabsOrSpaces.Collector do
  use Credo.Check.Consistency.Collector

  def collect_matches(source_file, _params) do
    source_file
    |> SourceFile.lines
    |> Enum.reduce(%{}, fn(line, stats) ->
        match = indented_with(line)

        if match, do: Map.update(stats, match, 1, &(&1 + 1)), else: stats
      end)
  end

  def find_locations(type, source_file) do
    source_file
    |> SourceFile.lines
    |> List.foldr([], fn({line_no, _} = line, line_nos) ->
      if indented_with(line) == type, do: [line_no | line_nos], else: line_nos
    end)
  end

  defp indented_with({_line_no, "  " <> _line}), do: :spaces
  defp indented_with({_line_no, "\t" <> _line}), do: :tabs
  defp indented_with({_, _}), do: nil
end
