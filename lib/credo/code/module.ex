defmodule Credo.Code.Module do
  @moduledoc """
  This module provides helper functions to analyse modules, return the defined
  funcions or module attributes.
  """

  alias Credo.Code
  alias Credo.Code.Block

  @def_ops [:def, :defp, :defmacro]

  @doc "Reads an attribute from a module's `ast`"
  def attribute(ast, attr_name) do
    case Credo.Code.traverse(ast, &find_attribute(&1, &2, attr_name), {:error, nil}) do
      {:ok, value} -> value
      error -> error
    end
  end

  defp find_attribute({:@, _meta, arguments} = ast, tuple, attribute_name) do
    case arguments |> List.first do
      {^attribute_name, _meta, [value]} -> {:ok, value}
      _ -> {ast, tuple}
    end
  end
  defp find_attribute(ast, tuple, _name) do
    {ast, tuple}
  end

  @doc "Returns the function/macro count for the given module's AST"
  def def_count(nil), do: 0
  def def_count({:defmodule, _, _arguments} = ast) do
    ast
    |> Code.traverse(&traverse_mod/2)
    |> Enum.count
  end

  @doc """
  Returns of the name of the function/macro defined in the given `ast`.
  """
  for op <- @def_ops ++ [:when] do
    def def_name_with_op({unquote(op) = op, _meta, arguments}) when is_list(arguments) do
      {arguments |> List.first |> def_name, op}
    end
    def def_name_with_op({unquote(op) = op, _meta, arguments}, arity) when is_list(arguments) do
      fun_def = arguments |> List.first
      if fun_def |> def_arity() == arity do
        {fun_def |> def_name, op}
      else
        nil
      end
    end
  end

  @doc """
  Returns the arity of the given function definition.
  """
  def def_arity({_fun_name, _, nil}), do: 0
  def def_arity({_fun_name, _, arguments}), do: Enum.count(arguments)

  @doc """
  Returns of the name of the function/macro defined in the given `ast`.
  """
  for op <- @def_ops ++ [:when] do
    def def_name({unquote(op), _meta, arguments}) when is_list(arguments) do
      arguments
      |> List.first
      |> def_name
    end
  end
  def def_name({fun_name, _meta, _arguments}) when is_atom(fun_name) do
    fun_name
  end
  def def_name(_), do: nil

  @doc "Returns the name of the functions/macros for the given module's `ast`"
  def def_names_with_op(nil), do: []
  def def_names_with_op({:defmodule, _, _arguments} = ast) do
    ast
    |> Code.traverse(&traverse_mod/2)
    |> Enum.map(&def_name_with_op/1)
    |> Enum.uniq
  end

  @doc "Returns the name of the functions/macros for the given module's `ast` if it has the given `arity`."
  def def_names_with_op(nil, _arity), do: []
  def def_names_with_op({:defmodule, _, _arguments} = ast, arity) do
    ast
    |> Code.traverse(&traverse_mod/2)
    |> Enum.map(&def_name_with_op(&1, arity))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq
  end

  @doc "Returns the name of the functions/macros for the given module's `ast`"
  def def_names(nil), do: []
  def def_names({:defmodule, _, _arguments} = ast) do
    ast
    |> Code.traverse(&traverse_mod/2)
    |> Enum.map(&def_name/1)
    |> Enum.uniq
  end

  for op <- @def_ops do
    def traverse_mod({unquote(op), _, arguments} = ast, defs) when is_list(arguments) do
      {ast, defs ++ [ast]}
    end
  end
  def traverse_mod(ast, defs) do
    {ast, defs}
  end

  # TODO: write unit test
  def name({:defmodule, _, [{:__aliases__, _, name_list}, _]}) do
    Enum.join(name_list, ".")
  end
  def name(_), do: nil

  # TODO: write unit test
  def exception?({:defmodule, _, [{:__aliases__, _, _name_list}, arguments]}) do
    arguments
    |> Block.calls_in_do_block
    |> Enum.any?(&defexception?/1)
  end
  def exception?(_), do: nil

  defp defexception?({:defexception, _, _}), do: true
  defp defexception?(_), do: false

end
