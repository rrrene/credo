defmodule Credo.Check.Consistency.ParameterPatternMatching.PositionCollector do
  use Credo.Check.CodePattern

  alias Credo.Code.Module
  alias Credo.Code.Name
  alias Credo.CLI.Filename

  def property_value, do: nil

  def property_value_for(%SourceFile{ast: ast, filename: filename}, _params) do
    foo = Credo.Code.prewalk(ast, &traverse(&1, &2, filename))
    IO.puts("results: #{inspect foo}")
    foo
  end

  defp traverse({:defmodule, _meta, [{:__aliases__, _, _name_arr}, _arguments]} = ast, property_values, filename) do
    new_property_values = 
      Module.defs(ast) 
        |> Enum.flat_map(&(property_values_for_def(&1, filename)))
    {:ast, property_values ++ new_property_values}   
  end
  
  defp traverse(ast, property_values, _filename) do
    {ast, property_values}
  end

  defp property_values_for_def({:def, [line: line_no], [{name, line_no2, parameters}, _]}, filename) when is_list(parameters) do
    parameters
      |> Enum.map(&(property_values_for_parameter(&1, filename)))
      |> Enum.reject(&is_nil/1)      
  end

  defp property_values_for_parameter({:=, [line: line_no], [[_ | _] | _]} = p, filename) do
    :after 
      |> PropertyValue.for(filename: filename, line_no: line_no)
  end

  defp property_values_for_parameter({:=, [line: line_no], [{:%, _, _}, _]} = p, filename) do
    :after
      |> PropertyValue.for(filename: filename, line_no: line_no)

  end

  defp property_values_for_parameter({:=, [line: line_no], [{:%{}, _, _}, _]} = p, filename) do
    :after
      |> PropertyValue.for(filename: filename, line_no: line_no)      
  end

  defp property_values_for_parameter({:=, [line: line_no], _} = p, filename) do
    :before
      |> PropertyValue.for(filename: filename, line_no: line_no)    
  end  

  defp property_values_for_parameter(_, _), do: nil

  defp property_values_for_def(_, _), do: nil

end