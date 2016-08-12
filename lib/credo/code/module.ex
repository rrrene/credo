defmodule Credo.Code.Module do
  @moduledoc """
  This module provides helper functions to analyse modules, return the defined
  funcions or module attributes.
  """

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
    |> Credo.Code.postwalk(&traverse_mod/2)
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
    |> Credo.Code.postwalk(&traverse_mod/2)
    |> Enum.map(&def_name/1)
    |> Enum.uniq
  end

  @doc "Returns the name of the functions/macros for the given module's `ast`"
  def def_names_with_op(nil), do: []
  def def_names_with_op({:defmodule, _, _arguments} = ast) do
    ast
    |> Credo.Code.postwalk(&traverse_mod/2)
    |> Enum.map(&def_name_with_op/1)
    |> Enum.uniq
  end

  @doc "Returns the name of the functions/macros for the given module's `ast` if it has the given `arity`."
  def def_names_with_op(nil, _arity), do: []
  def def_names_with_op({:defmodule, _, _arguments} = ast, arity) do
    ast
    |> Credo.Code.postwalk(&traverse_mod/2)
    |> Enum.map(&def_name_with_op(&1, arity))
    |> Enum.reject(&is_nil/1)
    |> Enum.uniq
  end

  @doc "Returns the list of modules used in a given module source code (dependent modules)"
  def modules({:defmodule, _, _arguments} = ast) do
    ast
    |> Credo.Code.postwalk(&find_dependent_modules/2)
    |> Enum.uniq
  end

  @doc "Returns the list of aliases defined in a given module ast"
  def aliases({:defmodule, _, _arguments} = ast) do
    ast
    |> Credo.Code.postwalk(&find_aliases/2)
    |> Enum.uniq
  end

  @doc "Returns the list of behaviours defined in a given module ast"
  # We need to camelize_behaviour, because there are different return values
  # from module_info[:attributes][:behaviour] depending on elixir version
  def behaviours({:defmodule, _, [{:__aliases__, _, mod_list}, _do_block]}) do
    module = mod_list |> Credo.Code.Name.to_module

    if Code.ensure_loaded?(module) do
      module.module_info[:attributes]
      |> Keyword.get_values(:behaviour)
      |> List.flatten
      |> Enum.map(&camelize_behaviour/1)
    else
      []
    end
  end
  def behaviours(_), do: []

  @doc "Returns the keyword list of callbacks defined in a given module"
  def callbacks(behaviour) when is_atom(behaviour) do
      [callbacks_from_module_attributes(behaviour) |
       callbacks_from_source_file(behaviour)]
      |> List.flatten
      |> Enum.uniq
  end
  def callbacks(_), do: []

  #
  # PRIVATE STUFF
  #

  defp callbacks_from_module_attributes(behaviour) do
    if Code.ensure_loaded?(behaviour) do
      behaviour.module_info[:attributes]
      |> Keyword.get_values(:callback)
      |> List.flatten
      |> Enum.map(&(elem(&1, 0)))
    else
      []
    end
  end

  defp callbacks_from_source_file(behaviour) do
    source_file = behaviour |> Credo.Sources.find

    if source_file do
      ast = source_file.ast

      Credo.Code.postwalk(ast, &find_callbacks/2)
    else
      []
    end
  end

  defp camelize_behaviour(behaviour) do
    behaviour_name = behaviour |> to_string

    if Credo.Code.Name.snake_case?(behaviour_name) do
      behaviour_name
      |> Mix.Utils.camelize
      |> Credo.Code.Name.with_prefix
      |> String.to_atom
    else
      behaviour
    end
  end


  # Single alias
  defp find_aliases({:alias, _, [{:__aliases__, _, mod_list}]} = ast, aliases) do
    module_names = mod_list |> Credo.Code.Name.full |> List.wrap
    {ast, aliases ++ module_names}
  end
  # Multi alias
  defp find_aliases({:alias, _, [{{:., _, [{:__aliases__, _, mod_list}, :{}]}, _, multi_mod_list}]} = ast, aliases) do
    module_names =
      multi_mod_list
      |> Enum.map(fn(tuple) ->
          [Credo.Code.Name.full(mod_list), Credo.Code.Name.full(tuple)] |> Credo.Code.Name.full
        end)

    {ast, aliases ++ module_names}
  end
  defp find_aliases(ast, aliases) do
    {ast, aliases}
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

  # exclude module name
  defp find_dependent_modules({:defmodule, _, [{:__aliases__, _, mod_list}, _do_block]} = ast, modules) do
    module_names = mod_list |> Credo.Code.Name.full |> List.wrap
    {ast, modules -- module_names}
  end
  # single alias
  defp find_dependent_modules({:alias, _, [{:__aliases__, _, mod_list}]} = ast, aliases) do
    module_names = mod_list |> Credo.Code.Name.full |> List.wrap
    {ast, aliases -- module_names}
  end
  # multi alias
  defp find_dependent_modules({:alias, _, [{{:., _, [{:__aliases__, _, mod_list}, :{}]}, _, multi_mod_list}]} = ast, modules) do
    module_names =
      multi_mod_list
      |> Enum.flat_map(fn(tuple) ->
          [Credo.Code.Name.full(mod_list), Credo.Code.Name.full(tuple)]
        end)

    {ast, modules -- module_names}
  end
  defp find_dependent_modules({:__aliases__, _, mod_list} = ast, modules) do
    module_names = mod_list |> Credo.Code.Name.full |> List.wrap
    {ast, modules ++ module_names}
  end
  defp find_dependent_modules(ast, modules) do
    {ast, modules}
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


  def find_callbacks({:callback, meta, [{:when, _, [{:::, _, [{callback_name, _, args}, _return_type]} = ast, _]}]}, callbacks) when is_list(args) do
    find_callbacks({:callback, meta, [ast]}, callbacks)
  end
  def find_callbacks({:callback, _, [{:::, _, [{callback_name, _, args}, _return_type]}]} = ast, callbacks) when is_list(args) do
    callback_arity = args |> Enum.count

    {ast, [{callback_name, callback_arity} | callbacks]}
  end
  def find_callbacks(ast, callbacks) do
    {ast, callbacks}
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

