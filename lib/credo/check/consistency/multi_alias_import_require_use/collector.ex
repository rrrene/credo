defmodule Credo.Check.Consistency.MultiAliasImportRequireUse.Collector do
  @moduledoc false

  use Credo.Check.Consistency.Collector

  @directives [:alias, :import, :require, :use]

  def collect_matches(source_file, _params) do
    source_file
    |> Credo.Code.prewalk(&traverse/2, {%{}, nil})
    |> elem(0)
    |> Enum.map(fn {_mod_name, aliases} ->
      aliases
      |> group_usages
      |> count_occurrences
    end)
    |> merge_module_stats()
  end

  def find_locations_not_matching(expected, source_file) do
    source_file
    |> Credo.Code.prewalk(&traverse/2, {%{}, nil})
    |> elem(0)
    |> Enum.map(fn {_mod_name, aliases} ->
      aliases
      |> group_usages
      |> drop_locations(expected)
    end)
    |> List.flatten()
  end

  defp traverse({:defmodule, _, [{:__aliases__, _, mod_name} | _]} = ast, {acc, _}) do
    {ast, {Map.put(acc, mod_name, []), mod_name}}
  end

  defp traverse({op, _, _}, acc) when op in [:def, :defp] do
    {nil, acc}
  end

  defp traverse({directive, meta, arguments} = ast, {acc, current_module})
       when directive in @directives and not is_nil(current_module) do
    aliases =
      case arguments do
        [{:__aliases__, _, nested_modules}] when length(nested_modules) > 1 ->
          base_name = Enum.slice(nested_modules, 0..-2//1)
          {:single, base_name}

        [{{:., _, [{:__aliases__, _, _namespaces}, :{}]}, _, _nested_aliases}] ->
          :multi

        _ ->
          nil
      end

    if aliases do
      updated_acc =
        Map.update(acc, current_module, [], fn entries ->
          [{directive, aliases, meta[:line]} | entries]
        end)

      {ast, {updated_acc, current_module}}
    else
      {ast, {acc, current_module}}
    end
  end

  defp traverse(ast, acc), do: {ast, acc}

  defp group_usages(usages) do
    split_with(usages, fn
      {_directive, :multi, _line_no} -> true
      _ -> false
    end)
  end

  defp count_occurrences({multi, single}) do
    stats = [
      multi: Enum.count(multi),
      single: single |> multiple_single_locations |> Enum.count()
    ]

    stats
    |> Enum.filter(fn {_, count} -> count > 0 end)
    |> Enum.into(%{})
  end

  defp drop_locations({_, single}, :multi), do: multiple_single_locations(single)

  defp drop_locations({multi, _}, :single), do: multi_locations(multi)

  defp multi_locations(multi_usages) do
    Enum.map(multi_usages, fn {_directive, :multi, line_no} -> line_no end)
  end

  defp multiple_single_locations(single_usages) do
    single_usages
    |> Enum.group_by(fn {directive, base_name, _line_no} ->
      {directive, base_name}
    end)
    |> Enum.filter(fn {_grouped_by, occurrences} ->
      Enum.count(occurrences) > 1
    end)
    |> Enum.map(fn {_grouped_by, [{_, _, line_no} | _]} -> line_no end)
  end

  # Enum.split_with/2 is not available on Elixir < 1.4
  # see https://github.com/elixir-lang/elixir/blob/v1.4.4/lib/elixir/lib/enum.ex#L1620
  defp split_with(enumerable, fun) when is_function(fun, 1) do
    {acc1, acc2} =
      Enum.reduce(enumerable, {[], []}, fn entry, {acc1, acc2} ->
        if fun.(entry) do
          {[entry | acc1], acc2}
        else
          {acc1, [entry | acc2]}
        end
      end)

    {:lists.reverse(acc1), :lists.reverse(acc2)}
  end

  defp merge_module_stats(stats_list) do
    Enum.reduce(stats_list, %{}, fn stats, acc ->
      Enum.reduce(stats, acc, fn {key, val}, acc ->
        Map.update(acc, key, val, &(&1 + val))
      end)
    end)
  end
end
