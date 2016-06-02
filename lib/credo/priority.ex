defmodule Credo.Priority do
  alias Credo.Code.Module
  alias Credo.Code.Parameters
  alias Credo.Code.Scope
  alias Credo.SourceFile

  @def_ops [:def, :defp, :defmacro]
  @many_functions_count 5

  def scope_priorities(%SourceFile{} = source_file) do
    empty_priorities =
      1..length(source_file.lines)
      |> Enum.map(fn(_) -> [] end)

    priority_list = Credo.Code.traverse(source_file, &traverse/2, empty_priorities)

    base_map =
      priority_list
      |> Enum.with_index
      |> Enum.map(fn({list, index}) ->
          case list do
            [] -> nil
            _ ->
              {_, scope_name} = Scope.name(source_file.ast, line: index + 1)
              {scope_name, sum(list)}
          end
        end)
      |> Enum.reject(&is_nil/1)

    lookup =
      base_map
      |> Enum.into(%{})

    base_map
    |> Enum.map(fn({scope_name, prio}) ->
        names = scope_name |> String.split(".")
        if names |> List.last |> String.match?(~r/^[a-z]/) do
          mod_name = names |> Enum.slice(0..length(names) - 2) |> Enum.join(".")
          mod_prio = lookup[mod_name]
          {scope_name, prio + mod_prio}
        else
          {scope_name, prio}
        end
      end)
    |> Enum.into(%{})
  end

  defp sum(list, acc \\ 0)
  defp sum([], acc), do: acc
  defp sum([head|tail], acc), do: sum(tail, acc + head)

  defp traverse({:defmodule, meta, _} = ast, acc) do
    added_prio = priority_for(ast)

    {ast, List.update_at(acc, meta[:line] - 1, &(&1 ++ [added_prio]))}
  end
  for op <- @def_ops do
    defp traverse({unquote(op), meta, arguments} = ast, acc) when is_list(arguments) do
      added_prio = priority_for(ast)

      {ast, List.update_at(acc, meta[:line] - 1, &(&1 ++ [added_prio]))}
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
    defp priority_for({unquote(op), _, arguments} = ast) when is_list(arguments) do
      count = Parameters.count(ast)
      cond do
        count == 0    -> 0
        count in 1..2 -> 1
        count in 3..4 -> 2
        true          -> 3
      end
    end
  end
end
