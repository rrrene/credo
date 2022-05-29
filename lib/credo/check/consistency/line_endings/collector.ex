defmodule Credo.Check.Consistency.LineEndings.Collector do
  @moduledoc false

  use Credo.Check.Consistency.Collector

  def collect_matches(source_file, _params) do
    source_file
    |> SourceFile.lines()
    # remove the last line since it behaves differently on windows and linux
    # and apparently does not help determining line endings (see #965)
    |> List.delete_at(-1)
    |> Enum.reduce(%{}, fn line, stats ->
      Map.update(stats, line_ending(line), 1, &(&1 + 1))
    end)
  end

  def first_line_with_issue(expected, source_file) do
    {line_no, _} =
      source_file
      |> SourceFile.lines()
      |> Enum.find(&(line_ending(&1) != expected))

    line_no
  end

  defp line_ending({_line_no, line}) do
    if String.ends_with?(line, "\r") do
      :windows
    else
      :unix
    end
  end
end
