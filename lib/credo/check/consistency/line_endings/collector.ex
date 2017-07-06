defmodule Credo.Check.Consistency.LineEndings.Collector do
  use Credo.Check.Consistency.Collector

  def collect_matches(source_file, _params) do
    source_file
    |> SourceFile.lines
    |> Enum.reduce(%{}, fn(line, stats) ->
        Map.update(stats, line_ending(line), 1, &(&1 + 1))
      end)
  end

  defp line_ending({_line_no, line}) do
    if String.ends_with?(line, "\r") do
      :windows
    else
      :unix
    end
  end
end
