defmodule Credo.Check.Consistency.LineEndings.Unix do
  use Credo.Check.CodePattern

  def property_value, do: :unix

  def property_value_for(source_file, _params) do
    source_file
    |> SourceFile.lines
    |> Enum.map(&property_value_for_line/1)
  end

  defp property_value_for_line({line_no, line}) do
    unless String.ends_with?(line, "\r") do
      PropertyValue.for(property_value(), line_no: line_no)
    end
  end
end
