defmodule Credo.Check.Consistency.ModuleAttributeOrder.Collector do
  @moduledoc false

  use Credo.Check.Consistency.Collector

  alias Credo.Code

  def collect_matches(source_file, _params) do
    source_file
    |> Code.prewalk(&traverse_file/2, [])
    |> collapse()
  end

  def find_locations_not_matching(expected, source_file) do
    source_file
    |> Code.prewalk(&traverse_file/2, [])
    |> collapse()

    # |> drop_locations(expected)
  end

  defp traverse_file({:defmodule, _, [_name, [do: content]]} = ast, file_attributes) do
    {_, module_attributes} = Macro.prewalk(content, [], &traverse_module/2)

    {ast, [module_attributes | file_attributes]}
  end

  defp traverse_file(ast, file_attributes), do: {ast, file_attributes}

  defp traverse_module({:defmodule, meta, [name, _]}, attributes) do
    {{:defmodule, meta, [name, [do: :ok]]}, attributes}
  end

  defp traverse_module(ast, attributes) do
    case match_attribute(ast) do
      nil -> {ast, attributes}
      attribute -> {ast, [attribute | attributes]}
    end
  end

  for attribute <- [:moduledoc, :behaviour, :type, :callback, :macrocallback, :optional_callbacks] do
    defp match_attribute({:@, _, [{unquote(attribute), _, _}]}), do: unquote(attribute)
  end

  for attribute <- [:use, :import, :alias, :require, :defstruct, :@] do
    defp match_attribute({unquote(attribute), _, _}), do: unquote(attribute)
  end

  defp match_attribute(_), do: nil

  defp collapse(file_attributes) do
    Enum.reduce(file_attributes, %{}, fn attributes, map ->
      attributes =
        attributes
        |> Enum.reverse()
        |> Enum.uniq()

      Map.update(map, attributes, 1, &(&1 + 1))
    end)
  end
end
