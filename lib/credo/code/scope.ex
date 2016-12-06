defmodule Credo.Code.Scope do
  @moduledoc """
  This module provides helper functions to determine the scope name at a certain
  point in the analysed code.
  """

  alias Credo.Code.Block
  alias Credo.Code.Module

  @def_ops [:def, :defp, :defmacro]


  def mod_name(nil), do: nil
  def mod_name(scope_name) do
    names = String.split(scope_name, ".")
    base_name = List.last(names)

    if String.match?(base_name, ~r/^[a-z]/) do
      names
      |> Enum.slice(0..length(names) - 2)
      |> Enum.join(".")
    else
      scope_name
    end
  end

  @doc """
  Returns the scope for the given line as a tuple consisting of the call to
  define the scope (`:defmodule`, `:def`, `:defp` or `:defmacro`) and the
  name of the scope.

  Examples:

    {:defmodule, "Foo.Bar"}
    {:def, "Foo.Bar.baz"}
  """
  def name(_ast, [line: 0]), do: nil
  def name(ast, [line: line]) do
    result =
      case find_scope(ast, line, [], nil) do
        nil -> name(ast, line: line - 1)
        {op, list} -> {op, Enum.join(list, ".")}
      end

    result || {nil, ""}
  end

  # Returns a List for the scope name
  defp find_scope({:__block__, _meta, arguments}, line, name_list, last_op) do
    find_scope(arguments, line, name_list, last_op)
  end
  defp find_scope({:do, arguments}, line, name_list, last_op) do
    find_scope(arguments, line, name_list, last_op)
  end
  defp find_scope({:else, arguments}, line, name_list, last_op) do
    find_scope(arguments, line, name_list, last_op)
  end
  defp find_scope(list, line, name_list, last_op) when is_list(list) do
    Enum.find_value(list, &find_scope(&1, line, name_list, last_op))
  end
  defp find_scope({:defmodule, meta, [{:__aliases__, _, module_name}, arguments]}, line, name_list, _last_op) do
    name_list = name_list ++ module_name

    cond do
      meta[:line] == line ->
        {:defmodule, name_list}
      meta[:line] > line ->
        nil
      true ->
        arguments
        |> Block.do_block_for!
        |> find_scope(line, name_list, :defmodule)
    end
  end
  for op <- @def_ops do
    defp find_scope({unquote(op) = op, meta, arguments} = ast, line, name_list, _last_op) when is_list(arguments) do
      fun_name = Module.def_name(ast)
      name_list = name_list ++ [fun_name]

      cond do
        meta[:line] == line ->
          {op, name_list}
        meta[:line] > line ->
          nil
        true ->
          arguments
          |> Block.do_block_for!
          |> find_scope(line, name_list, op)
      end
    end
  end
  defp find_scope({_atom, meta, arguments}, line, name_list, last_op) do
    if meta[:line] == line do
      {last_op, name_list}
    else
      find_scope(arguments, line, name_list, last_op)
    end
  end
  defp find_scope(_value, _line, _name_list, _last_op) do
    nil
  end
end
