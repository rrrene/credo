defmodule Credo.Check.Consistency.ExceptionNames.PrefixAndSuffixCollector do
  use Credo.Check.CodePattern

  alias Credo.Code.Module
  alias Credo.Code.Name

  def property_value, do: nil

  def property_value_for(source_file, _params) do
    Credo.Code.prewalk(source_file, &traverse/2)
  end

  defp traverse({:defmodule, _meta, [{:__aliases__, _, _name_arr}, _arguments]} = ast, property_values) do
    if Module.exception?(ast) do
      name = Module.name(ast)
      new_property_values = property_value_for_exception_name(name, ast)

      {ast, property_values ++ List.wrap(new_property_values)}
    else
      {ast, property_values}
    end
  end
  defp traverse(ast, property_values) do
    {ast, property_values}
  end

  defp property_value_for_exception_name(name, {_, meta, _}) do
    name_list = name |> Name.last |> Name.split_pascal_case
    prefix = List.first(name_list)
    suffix = List.last(name_list)

    [
      PropertyValue.for({prefix, :prefix}, [line_no: meta[:line]]),
      PropertyValue.for({suffix, :suffix}, [line_no: meta[:line]])
    ]
  end
end
