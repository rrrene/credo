defmodule Credo.Code.Parameters do
  @moduledoc """
  This module provides helper functions to analyse the parameters taken by a
  function.
  """

  @def_ops [:def, :defp, :defmacro]

  @doc "Returns the parameter count for the given function's AST"
  def count(nil), do: 0

  for op <- @def_ops do
    def count({unquote(op), _, arguments}) when is_list(arguments) do
      case List.first(arguments) do
        {_atom, _meta, nil} ->
          0

        {_atom, _meta, list} ->
          Enum.count(list)

        _ ->
          0
      end
    end
  end

  @doc "Returns the names of all parameters for the given function's AST"
  def names(nil), do: nil

  for op <- @def_ops do
    def names({unquote(op), _meta, arguments}) when is_list(arguments) do
      arguments
      |> List.first()
      |> get_param_names
    end
  end

  defp get_param_names({:when, _meta, arguments}) do
    arguments
    |> List.first()
    |> get_param_names
  end

  defp get_param_names(arguments) when is_tuple(arguments) do
    arguments
    |> Tuple.to_list()
    |> List.last()
    |> Enum.map(&get_param_name/1)
    |> Enum.reject(&is_nil/1)
  end

  defp get_param_name({:"::", _, [var, _type]}) do
    get_param_name(var)
  end

  defp get_param_name({:<<>>, _, arguments}) do
    arguments
    |> Enum.map(&get_param_name/1)
    |> Enum.reject(&is_nil/1)
  end

  defp get_param_name({:=, _, arguments}) do
    arguments
    |> Enum.map(&get_param_name/1)
    |> Enum.reject(&is_nil/1)
  end

  defp get_param_name({:%, _, [{:__aliases__, _meta, _mod_list}, {:%{}, _meta2, arguments}]}) do
    get_param_name(arguments)
  end

  defp get_param_name({:%{}, _, arguments}) do
    get_param_name(arguments)
  end

  defp get_param_name({:\\, _, arguments}) do
    Enum.find_value(arguments, &get_param_name/1)
  end

  defp get_param_name(list) when is_list(list) do
    list
    |> Enum.map(fn {atom, tuple} when is_atom(atom) and is_tuple(tuple) ->
      get_param_name(tuple)
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp get_param_name({name, _, nil}) when is_atom(name), do: name

  defp get_param_name(_) do
    nil
  end
end
