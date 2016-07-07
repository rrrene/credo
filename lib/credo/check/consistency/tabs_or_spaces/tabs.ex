defmodule Credo.Check.Consistency.TabsOrSpaces.Tabs do
  use Credo.Check.CodePattern

  def property_value, do: :tabs

  def property_value_for(%SourceFile{lines: lines, filename: filename}, _params) do
    lines
    |> Enum.map(&property_value_for_line(&1, filename))
  end

  defp property_value_for_line({line_no, "\t" <> _line}, filename) do
    property_value()
    |> PropertyValue.for(filename: filename, line_no: line_no)
  end
  defp property_value_for_line({_, _}, _), do: nil
end
