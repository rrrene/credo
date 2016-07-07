defmodule Credo.Check.Consistency.LineEndings.Windows do
  use Credo.Check.CodePattern

  def property_value, do: :windows

  def property_value_for(%SourceFile{lines: lines, filename: filename}, _params) do
    lines
    |> Enum.map(&property_value_for_line(&1, filename))
  end

  defp property_value_for_line({line_no, line}, filename) do
    if String.ends_with?(line, "\r") do
      property_value()
      |> PropertyValue.for(filename: filename, line_no: line_no)
    end
  end
end
