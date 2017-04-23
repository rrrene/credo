defmodule Credo.Code.Module do
  @moduledoc """
  This module provides helper functions to analyse modules, return the defined
  funcions or module attributes.
  """

  alias Credo.Code
  alias Credo.Code.Block
  alias Credo.Code.Name

  @def_ops [:def, :defp, :defmacro]



  @doc "Returns the list of aliases defined in a given module source code."
  def aliases({:defmodule, _, _arguments} = ast) do
    ast
    |> Credo.Code.postwalk(&find_aliases/2)
    |> Enum.uniq
  end

  defp find_aliases({:alias, _, [{:__aliases__, _, mod_list}]} = ast, aliases) do
    module_names =
      mod_list
      |> Name.full
      |> List.wrap

    {ast, aliases ++ module_names}
  end
  # Multi alias
  defp find_aliases({:alias, _, [{{:., _, [{:__aliases__, _, mod_list}, :{}]}, _, multi_mod_list}]} = ast, aliases) do
    module_names =
      Enum.map(multi_mod_list, fn(tuple) ->
        Name.full([Name.full(mod_list), Name.full(tuple)])
      end)

    {ast, aliases ++ module_names}
  end
  defp find_aliases(ast, aliases) do
    {ast, aliases}
  end



  @doc "Reads an attribute from a module's `ast`"
  def attribute(ast, attr_name) do
    case Code.postwalk(ast, &find_attribute(&1, &2, attr_name), {:error, nil}) do
      {:ok, value} ->
        value
      error ->
        error
    end
  end

  defp find_attribute({:@, _meta, arguments} = ast, tuple, attribute_name) do
    case List.first(arguments) do
      {^attribute_name, _meta, [value]} ->
        {:ok, value}
      _ ->
        {ast, tuple}
    end
  end
  defp find_attribute(ast, tuple, _name) do
    {ast, tuple}
  end



  @doc "Returns the function/macro count for the given module's AST"
  def def_count(nil), do: 0
  def def_count({:defmodule, _, _arguments} = ast) do
    ast
    |> Code.postwalk(&collect_defs/2)
    |> Enum.count
  end

  def defs(nil), do: []
  def defs({:defmodule, _, _arguments} = ast) do
    Code.postwalk(ast, &collect_defs/2)
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
      {def_name(ast), op}
    end
    def def_name_with_op({unquote(op) = op, _, _} = ast, arity) do
      if def_arity(ast) == arity do
        {def_name(ast), op}
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
    |> Code.postwalk(&collect_defs/2)
    |> Enum.map(&def_name/1)
    |> Enum.uniq
  end



  @doc "Returns the name of the functions/macros for the given module's `ast`"
  def def_names_with_op(nil), do: []
  def def_names_with_op({:defmodule, _, _arguments} = ast) do
    ast
    |> Code.postwalk(&collect_defs/2)
    |> Enum.map(&def_name_with_op/1)
    |> Enum.uniq
  end



  @doc "Returns the name of the functions/macros for the given module's `ast` if it has the given `arity`."
  def def_names_with_op(nil, _arity), do: []
  def def_names_with_op({:defmodule, _, _arguments} = ast, arity) do
    ast
    |> Code.postwalk(&collect_defs/2)
    |> Enum.map(&def_name_with_op(&1, arity))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq
  end

  for op <- @def_ops do
    defp collect_defs({:@, _, [{unquote(op), _, arguments} = ast]}, defs) when is_list(arguments) do
      {ast, defs -- [ast]}
    end
    defp collect_defs({unquote(op), _, arguments} = ast, defs) when is_list(arguments) do
      {ast, defs ++ [ast]}
    end
  end
  defp collect_defs(ast, defs) do
    {ast, defs}
  end



  @doc "Returns the list of modules used in a given module source code."
  def modules({:defmodule, _, _arguments} = ast) do
    ast
    |> Code.postwalk(&find_dependent_modules/2)
    |> Enum.uniq
  end

  # exclude module name
  defp find_dependent_modules({:defmodule, _, [{:__aliases__, _, mod_list}, _do_block]} = ast, modules) do
    module_names =
      mod_list
      |> Name.full
      |> List.wrap

    {ast, modules -- module_names}
  end
  # single alias
  defp find_dependent_modules({:alias, _, [{:__aliases__, _, mod_list}]} = ast, aliases) do
    module_names =
      mod_list
      |> Name.full
      |> List.wrap

    {ast, aliases -- module_names}
  end
  # multi alias
  defp find_dependent_modules({:alias, _, [{{:., _, [{:__aliases__, _, mod_list}, :{}]}, _, multi_mod_list}]} = ast, modules) do
    module_names =
      Enum.flat_map(multi_mod_list, fn(tuple) ->
        [Name.full(mod_list), Name.full(tuple)]
      end)

    {ast, modules -- module_names}
  end
  defp find_dependent_modules({:__aliases__, _, mod_list} = ast, modules) do
    module_names =
      mod_list
      |> Name.full
      |> List.wrap

    {ast, modules ++ module_names}
  end
  defp find_dependent_modules(ast, modules) do
    {ast, modules}
  end



  @doc "Returns the name of a module's given ast node."
  def name({:defmodule, _, [{:__aliases__, _, name_list}, _]}) do
    Enum.join(name_list, ".")
  end
  def name(_), do: "<Unknown Module Name>"



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

