defmodule Credo.Code.Scope do
  @moduledoc """
  This module provides helper functions to determine the scope name at a certain
  point in the analysed code.
  """

  @def_ops [:def, :defp, :defmacro]

  @doc """
  Returns the module part of a scope.

      iex> Credo.Code.Scope.mod_name("Credo.Code")
      "Credo.Code"

      iex> Credo.Code.Scope.mod_name("Credo.Code.ast")
      "Credo.Code"

  """
  def mod_name(nil), do: nil

  def mod_name(scope_name) do
    names = String.split(scope_name, ".")
    base_name = List.last(names)

    if String.match?(base_name, ~r/^[a-z]/) do
      names
      |> Enum.slice(0..(length(names) - 2))
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
  def name(_ast, line: 0), do: nil

  def name(ast, line: line) do
    ast
    |> scope_info_list()
    |> name_from_scope_info_list(line)
  end

  @doc false
  def name_from_scope_info_list(scope_info_list, line) do
    result =
      Enum.find(scope_info_list, fn
        {line_no, _op, _arguments} when line_no <= line -> true
        _ -> false
      end)

    case result do
      {_line_no, op, arguments} ->
        name = Credo.Code.Name.full(arguments)
        {op, name}

      _ ->
        {nil, ""}
    end
  end

  @doc false
  def scope_info_list(ast) do
    {_, scope_info_list} = Macro.prewalk(ast, [], &traverse_modules(&1, &2, nil, nil))

    Enum.reverse(scope_info_list)
  end

  defp traverse_modules({:defmodule, meta, arguments} = ast, acc, current_scope, _current_op)
       when is_list(arguments) do
    new_scope_part = Credo.Code.Module.name(ast)

    scope_name =
      [current_scope, new_scope_part]
      |> Enum.reject(&is_nil/1)
      |> Credo.Code.Name.full()

    defmodule_scope_info = {meta[:line], :defmodule, scope_name}

    {_, def_scope_infos} =
      Macro.prewalk(arguments, [], &traverse_defs(&1, &2, scope_name, :defmodule))

    new_acc = (acc ++ [defmodule_scope_info]) ++ def_scope_infos

    {nil, new_acc}
  end

  defp traverse_modules({_op, meta, _arguments} = ast, acc, current_scope, current_op) do
    scope_info = {meta[:line], current_op, current_scope}

    {ast, acc ++ [scope_info]}
  end

  defp traverse_modules(ast, acc, _current_scope, _current_op) do
    {ast, acc}
  end

  defp traverse_defs({:defmodule, _meta, arguments} = ast, acc, current_scope, _current_op)
       when is_list(arguments) do
    {_, scopes} = Macro.prewalk(ast, [], &traverse_modules(&1, &2, current_scope, :defmodule))

    {nil, acc ++ scopes}
  end

  for op <- @def_ops do
    defp traverse_defs({unquote(op), meta, arguments} = ast, acc, current_scope, _current_op)
         when is_list(arguments) do
      new_scope_part = Credo.Code.Module.def_name(ast)

      scope_name =
        [current_scope, new_scope_part]
        |> Enum.reject(&is_nil/1)
        |> Credo.Code.Name.full()

      scope_info = {meta[:line], unquote(op), scope_name}

      new_acc = acc ++ [scope_info]

      {nil, new_acc}
    end
  end

  defp traverse_defs({_op, meta, _arguments} = ast, acc, current_scope, current_op) do
    scope_info = {meta[:line], current_op, current_scope}

    {ast, acc ++ [scope_info]}
  end

  defp traverse_defs(ast, acc, _current_scope, _current_op) do
    {ast, acc}
  end
end
