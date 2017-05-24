defmodule Credo.Check.Consistency.PatternMatchingAssignment.RightSideAssignment do
  use Credo.Check.CodePattern

  def property_value, do: :right_side

  def property_value_for(%SourceFile{ast: ast, filename: filename}, _params) do
    Credo.Code.prewalk(ast, &traverse(&1, &2, filename))
  end

  defp traverse({:def, _, _} = node, property_values, filename) do
    {node, Credo.Code.prewalk(node, &parse_def(&1, &2, filename), property_values)}
  end

  defp traverse(node, property_values, _filename) do
    {node, property_values}
  end

  defp parse_def({:=, [line: line_no], [argument, {_, _, _}]} = node, property_values, filename) when is_atom(argument) do
    {node, [construct_property(line_no, node, filename) | property_values]}
  end

  defp parse_def({:=, [line: line_no], [{:%{}, _, _}, {_, _, _}]} = node, property_values, filename) do
    {node, [construct_property(line_no, node, filename) | property_values]}
  end

  defp parse_def({:=, [line: line_no], [{:%, _, [_, {:%{}, _, _}]}, {_, _, _}]} = node, property_values, filename) do
    {node, [construct_property(line_no, node, filename) | property_values]}
  end

  defp parse_def(node, property_values, _filename) do
    {node, property_values}
  end

  defp construct_property(line_no, node, filename) do
    PropertyValue.for(property_value(), line_no: line_no, trigger: Macro.to_string(node), filename: filename)
  end
end
