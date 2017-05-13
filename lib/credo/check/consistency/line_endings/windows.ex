defmodule Credo.Check.Consistency.LineEndings.Windows do
  use Credo.Check.CodePattern

  def property_value, do: :windows

  def property_value_for(%SourceFile{filename: filename} = source_file, _params) do
    lines = SourceFile.lines(source_file)

    Enum.map(lines, &property_value_for_line(&1, filename))
  end

  defp property_value_for_line({line_no, line}, filename) do
    if String.ends_with?(line, "\r") do
      PropertyValue.for(property_value(), filename: filename, line_no: line_no)
    end
  end
end
