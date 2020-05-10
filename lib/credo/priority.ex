defmodule Credo.Priority do
  @moduledoc false

  # In Credo each Issue is given a priority to differentiate issues by a second
  # dimension next to their Category.

  alias Credo.Code.Module
  alias Credo.Code.Parameters
  alias Credo.Code.Scope
  alias Credo.SourceFile

  @def_ops [:def, :defp, :defmacro]
  @many_functions_count 5

  @priority_names_map %{
    "ignore" => -100,
    "low" => -10,
    "normal" => 1,
    "high" => +10,
    "higher" => +20
  }

  @doc "Converts a given priority name to a numerical priority"
  def to_integer(nil), do: 0

  def to_integer(value) when is_number(value), do: value

  def to_integer(string) when is_binary(string) do
    case Integer.parse(string) do
      :error -> string |> String.to_atom() |> to_integer()
      {value, ""} -> value
      {_value, _rest} -> raise "Got an invalid priority: #{inspect(string)}"
    end
  end

  def to_integer(key) when is_atom(key) do
    @priority_names_map[to_string(key)] || raise "Got an invalid priority: #{inspect(key)}"
  end

  def scope_priorities(%SourceFile{} = source_file) do
    line_count =
      source_file
      |> SourceFile.lines()
      |> length()

    empty_priorities = Enum.map(1..line_count, fn _ -> [] end)

    priority_list = Credo.Code.prewalk(source_file, &traverse/2, empty_priorities)

    base_map = make_base_map(priority_list, source_file)

    lookup = Enum.into(base_map, %{})

    Enum.into(base_map, %{}, fn {scope_name, prio} ->
      names = String.split(scope_name, ".")

      if names |> List.last() |> String.match?(~r/^[a-z]/) do
        mod_name =
          names
          |> Enum.slice(0..(length(names) - 2))
          |> Enum.join(".")

        mod_prio = lookup[mod_name]

        {scope_name, prio + mod_prio}
      else
        {scope_name, prio}
      end
    end)
  end

  defp make_base_map(priority_list, %SourceFile{} = source_file) do
    ast = SourceFile.ast(source_file)
    scope_info_list = Scope.scope_info_list(ast)

    priority_list
    |> Enum.with_index()
    |> Enum.map(fn {list, index} ->
      case list do
        [] ->
          nil

        _ ->
          {_, scope_name} = Scope.name_from_scope_info_list(scope_info_list, index + 1)
          {scope_name, Enum.sum(list)}
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp traverse({:defmodule, meta, _} = ast, acc) do
    added_prio = priority_for(ast)

    {ast, List.update_at(acc, meta[:line] - 1, &(&1 ++ [added_prio]))}
  end

  for op <- @def_ops do
    defp traverse({unquote(op), meta, arguments} = ast, acc)
         when is_list(arguments) do
      added_prio = priority_for(ast)

      case arguments do
        [{_func_name, _meta, _func_arguments}, _do_block] ->
          {ast, List.update_at(acc, meta[:line] - 1, &(&1 ++ [added_prio]))}

        _ ->
          {ast, acc}
      end
    end
  end

  defp traverse(ast, acc) do
    {ast, acc}
  end

  defp priority_for({:defmodule, _, _} = ast) do
    if Module.def_count(ast) >= @many_functions_count do
      2
    else
      1
    end
  end

  for op <- @def_ops do
    defp priority_for({unquote(op), _, arguments} = ast)
         when is_list(arguments) do
      count = Parameters.count(ast)

      cond do
        count == 0 -> 0
        count in 1..2 -> 1
        count in 3..4 -> 2
        true -> 3
      end
    end
  end
end
