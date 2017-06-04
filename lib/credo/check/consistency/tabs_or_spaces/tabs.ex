defmodule Credo.Check.Consistency.TabsOrSpaces.Tabs do
  use Credo.Check.CodePattern

  def property_value, do: :tabs

  def property_value_for(source_file, _params) do
    source_file
    |> SourceFile.lines
    |> Enum.map(&property_value_for_line/1)
  end

  defp property_value_for_line({line_no, "\t" <> _line}) do
    PropertyValue.for(property_value(), line_no: line_no)
  end
  defp property_value_for_line({_, _}), do: nil
end
