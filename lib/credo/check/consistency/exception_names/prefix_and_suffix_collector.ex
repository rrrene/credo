defmodule Credo.Check.Consistency.ExceptionNames.PrefixAndSuffixCollector do
  use Credo.Check.CodePattern

  alias Credo.Code.Module
  alias Credo.Code.Name
  alias Credo.CLI.Filename

  def property_value, do: nil

  def property_value_for(%SourceFile{filename: filename} = source_file, _params) do
    Credo.Code.prewalk(source_file, &traverse(&1, &2, filename))
  end

  defp traverse({:defmodule, _meta, [{:__aliases__, _, _name_arr}, _arguments]} = ast, property_values, filename) do
    if Module.exception?(ast) do
      name = Module.name(ast)
      new_property_values = property_value_for_exception_name(name, ast, filename)

      {ast, property_values ++ List.wrap(new_property_values)}
    else
      {ast, property_values}
    end
  end
  defp traverse(ast, property_values, _filename) do
    {ast, property_values}
  end

  defp property_value_for_exception_name(name, {_, meta, _}, filename) do
    filename = Filename.with(filename, line_no: meta[:line])
    name_list = name |> Name.last |> Name.split_pascal_case
    prefix = List.first(name_list)
    suffix = List.last(name_list)

    [
      PropertyValue.for({prefix, :prefix}, filename),
      PropertyValue.for({suffix, :suffix}, filename)
    ]
  end
end
