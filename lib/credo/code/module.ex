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
    case Credo.Code.postwalk(ast, &find_attribute(&1, &2, attr_name), {:error, nil}) do
      {:ok, value} -> value
      error -> error
    end
  end

  @doc "Returns the function/macro count for the given module's AST"
  def def_count(nil), do: 0
  def def_count({:defmodule, _, _arguments} = ast) do
    ast
    |> Code.postwalk(&traverse_mod/2)
    |> Enum.count
  end

  @doc "Returns the arity of the given function definition `ast`"
  for op <- @def_ops do
    def def_arity({unquote(op) = op, _, [{:when, _, fun_ast}, _]}) do
      def_arity({op, nil, fun_ast})
    end
    def def_arity({unquote(op), _, [{_fun_name, _, arguments}, _]}) when is_list(arguments) do
      Enum.count(arguments)
    end
    def def_arity({unquote(op), _, [{_fun_name, _, _}, _]}), do: 0
  end
  def def_arity(_), do: nil

  @doc "Returns the name of the function/macro defined in the given `ast`"
  for op <- @def_ops do
    def def_name({unquote(op) = op, _, [{:when, _, fun_ast}, _]}) do
      def_name({op, nil, fun_ast})
    end
    def def_name({unquote(op), _, [{fun_name, _, _arguments}, _]}) when is_atom(fun_name) do
      fun_name
    end
  end
  def def_name(_), do: nil

  @doc "Returns the {fun_name, op} tuple of the function/macro defined in the given `ast`"
  for op <- @def_ops do
    def def_name_with_op({unquote(op) = op, _, _} = ast) do
      {ast |> def_name, op}
    end
    def def_name_with_op({unquote(op) = op, _, _} = ast, arity) do
      if ast |> def_arity() == arity do
        {ast |> def_name, op}
      else
        nil
      end
    end
  end
  def def_name_with_op(_), do: nil

  @doc "Returns the name of the functions/macros for the given module's `ast`"
  def def_names(nil), do: []
  def def_names({:defmodule, _, _arguments} = ast) do
    ast
    |> Code.postwalk(&traverse_mod/2)
    |> Enum.map(&def_name/1)
    |> Enum.uniq
  end

  @doc "Returns the name of the functions/macros for the given module's `ast`"
  def def_names_with_op(nil), do: []
  def def_names_with_op({:defmodule, _, _arguments} = ast) do
    ast
    |> Code.postwalk(&traverse_mod/2)
    |> Enum.map(&def_name_with_op/1)
    |> Enum.uniq
  end

  @doc "Returns the name of the functions/macros for the given module's `ast` if it has the given `arity`."
  def def_names_with_op(nil, _arity), do: []
  def def_names_with_op({:defmodule, _, _arguments} = ast, arity) do
    ast
    |> Code.postwalk(&traverse_mod/2)
    |> Enum.map(&def_name_with_op(&1, arity))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq
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

  for op <- @def_ops do
    defp traverse_mod({:@, _, [{unquote(op), _, arguments} = ast]}, defs) when is_list(arguments) do
      {ast, defs -- [ast]}
    end
    defp traverse_mod({unquote(op), _, arguments} = ast, defs) when is_list(arguments) do
      {ast, defs ++ [ast]}
    end
  end
  defp traverse_mod(ast, defs) do
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

