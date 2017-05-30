defmodule Credo.ExsLoader do
  def parse(exs_string, safe \\ false)
  def parse(exs_string, true) do
    case Code.string_to_quoted(exs_string) do
      {:ok, ast} ->
        process_exs(ast)
      _ -> %{}
    end
  end
  def parse(exs_string, false) do
    {result, _binding} = Code.eval_string(exs_string)
    result
  end

  def parse_safe(exs_string) do
    case Code.string_to_quoted(exs_string) do
      {:ok, ast} ->
        process_exs(ast)
      _ -> %{}
    end
  end

  defp process_exs(v) when is_atom(v)
                        or is_binary(v)
                        or is_float(v)
                        or is_integer(v), do: v
  defp process_exs(list) when is_list(list) do
    Enum.map(list, &process_exs/1)
  end

  defp process_exs({:sigil_w, _, [{:<<>>, _, [list_as_string]}, []]}) do
    String.split(list_as_string, ~r/\s+/)
  end

  # TODO: support regex modifiers
  defp process_exs({:sigil_r, _, [{:<<>>, _, [regex_as_string]}, []]}) do
    Regex.compile!(regex_as_string)
  end

  defp process_exs({:%{}, _meta, body}) do
    process_map(body, %{})
  end

  defp process_exs({:{}, _meta, body}) do
    process_tuple(body, {})
  end

  defp process_exs({:__aliases__, _meta, name_list}) do
    Module.safe_concat(name_list)
  end

  defp process_exs({{:__aliases__, _meta, name_list}, options}) do
    {Module.safe_concat(name_list), process_exs(options)}
  end

  defp process_exs({key, value}) when is_atom(key) or is_binary(key) do
    {process_exs(key), process_exs(value)}
  end

  defp process_tuple([], acc), do: acc
  defp process_tuple([head|tail], acc) do
    acc = process_tuple_item(head, acc)
    process_tuple(tail, acc)
  end

  defp process_tuple_item(value, acc) do
    Tuple.append(acc, process_exs(value))
  end

  defp process_map([], acc), do: acc
  defp process_map([head|tail], acc) do
    acc = process_map_item(head, acc)
    process_map(tail, acc)
  end

  defp process_map_item({key, value}, acc) when is_atom(key) or is_binary(key) do
    Map.put(acc, key, process_exs(value))
  end
end
