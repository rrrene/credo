defmodule Credo.Check.Consistency.ParameterPatternMatching.PositionCollector do
  use Credo.Check.CodePattern

  alias Credo.Code.Module

  def property_value, do: nil

  def property_value_for(source_file, _params) do
    Credo.Code.prewalk(source_file, &traverse/2)
  end

  defp traverse({:defmodule, _meta, [{:__aliases__, _, _name_arr}, _arguments]} = ast, property_values) do
    new_property_values =
      ast
      |> Module.defs
      |> Enum.flat_map(&property_values_for_def/1)

    {:ast, property_values ++ new_property_values}
  end

  defp traverse(ast, property_values) do
    {ast, property_values}
  end

  defp property_values_for_def({:def, _, [{_name, _, parameters}, _]}) when is_list(parameters) do
    parameters
    |> Enum.map(&property_values_for_parameter/1)
    |> Enum.reject(&is_nil/1)
  end
  defp property_values_for_def(_), do: []

  defp property_values_for_parameter({:=, _, [{name, meta, nil}, _rhs]} = _vals) when is_atom(name) do
    PropertyValue.for(:before, line_no: meta[:line])
  end
  defp property_values_for_parameter({:=, _, [_lhs, {name, meta, nil}]} = _vals) when is_atom(name) do
    PropertyValue.for(:after, line_no: meta[:line])
  end
  defp property_values_for_parameter(_), do: nil
end
