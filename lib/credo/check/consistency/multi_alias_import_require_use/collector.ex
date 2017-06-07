defmodule Credo.Check.Consistency.MultiAliasImportRequireUse.Collector do
  use Credo.Check.Consistency.Collector

  alias Credo.Code

  @directives [:alias, :import, :require, :use]

  def collect_matches(source_file, _params) do
    source_file
    |> Code.prewalk(&traverse/2, [])
    |> group_usages
    |> count_occurrences
  end

  def find_locations(matching, source_file) do
    source_file
    |> Code.prewalk(&traverse/2, [])
    |> group_usages
    |> filter_locations(matching)
  end

  defp traverse({directive, meta, arguments} = ast, acc) when directive in @directives do
    aliases =
      case arguments do
        [{:__aliases__, _, nested_modules}] when length(nested_modules) > 1 ->
          base_name = Enum.slice(nested_modules, 0..-2)
          {:single, base_name}
        [{{:., _, [{:__aliases__, _, _namespaces}, :{}]}, _, _nested_aliases}] ->
          :multi
        _ ->
          nil
      end

    if aliases, do: {ast, [{directive, aliases, meta[:line]} | acc]}, else: {ast, acc}
  end
  defp traverse(ast, acc), do: {ast, acc}

  defp group_usages(usages) do
    Enum.split_with(usages, fn
      {_directive, :multi, _line_no} -> true
      _ -> false
    end)
  end

  defp count_occurrences({multi, single}) do
    stats =
      [multi: Enum.count(multi),
       single: single |> multiple_single_locations |> Enum.count]

    stats
    |> Enum.filter(fn({_, count}) -> count > 0 end)
    |> Enum.into(%{})
  end

  defp filter_locations({multi, _}, :multi), do: multi_locations(multi)

  defp filter_locations({_, single}, :single), do: multiple_single_locations(single)

  defp multi_locations(multi_usages) do
    Enum.map(multi_usages,
      fn({_directive, :multi, line_no}) -> line_no end)
  end

  defp multiple_single_locations(multiple_single_usages) do
    multiple_single_usages
    |> Enum.group_by(
        fn({directive, base_name, _line_no}) -> {directive, base_name} end,
        fn({_directive, _base_name, line_no}) -> line_no end)
    |> Enum.filter(
        fn({_grouped_by, line_nos}) -> Enum.count(line_nos) > 1 end)
    |> Enum.map(
        fn({_grouped_by, line_nos}) -> List.first(line_nos) end)
  end
end
