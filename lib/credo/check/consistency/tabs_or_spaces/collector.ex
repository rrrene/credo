defmodule Credo.Check.Consistency.TabsOrSpaces.Collector do
  use Credo.Check.Consistency.Collector

  def collect_matches(source_file, _params) do
    source_file
    |> SourceFile.lines
    |> Enum.reduce(%{}, fn(line, stats) ->
        match = indentation(line)

        if match do
          Map.update(stats, match, 1, &(&1 + 1))
        else
          stats
        end
      end)
  end

  def find_locations_not_matching(expected, source_file) do
    source_file
    |> SourceFile.lines
    |> List.foldr([], fn({line_no, _} = line, line_nos) ->
      if indentation(line) && indentation(line) != expected do
        [line_no | line_nos]
      else
        line_nos
      end
    end)
  end

  defp indentation({_line_no, "  " <> _line}), do: :spaces
  defp indentation({_line_no, "\t" <> _line}), do: :tabs
  defp indentation({_, _}), do: nil
end
