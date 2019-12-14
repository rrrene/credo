defmodule Credo.Check.Consistency.UnusedVariableNames.Collector do
  @moduledoc false

  use Credo.Check.Consistency.Collector

  alias Credo.Code

  def collect_matches(source_file, _params) do
    unused_variable_recorder = &record_unused_variable/2

    Code.prewalk(source_file, &traverse(unused_variable_recorder, &1, &2), %{})
  end

  def find_locations_not_matching(expected, source_file) do
    location_recorder = &record_not_matching(expected, &1, &2)

    source_file
    |> Code.prewalk(&traverse(location_recorder, &1, &2), [])
    |> Enum.reverse()
  end

  defp traverse(callback, {:=, _, params} = ast, acc) do
    {ast, reduce_unused_variables(params, callback, acc)}
  end

  defp traverse(callback, {def, _, [{_, _, params} | _]} = ast, acc)
       when def in [:def, :defp] do
    {ast, reduce_unused_variables(params, callback, acc)}
  end

  defp traverse(callback, {:->, _, [params | _]} = ast, acc) do
    {ast, reduce_unused_variables(params, callback, acc)}
  end

  defp traverse(_callback, ast, acc), do: {ast, acc}

  defp reduce_unused_variables(nil, _callback, acc), do: acc

  defp reduce_unused_variables(ast, callback, acc) do
    Enum.reduce(ast, acc, &if(unused_variable_name?(&1), do: callback.(&1, &2), else: &2))
  end

  defp unused_variable_name?({:_, _, _}), do: true

  defp unused_variable_name?({name, _, _}) when is_atom(name),
    do: String.starts_with?(Atom.to_string(name), "_")

  defp unused_variable_name?(_), do: false

  defp record_unused_variable({:_, _, _}, acc), do: Map.update(acc, :anonymous, 1, &(&1 + 1))
  defp record_unused_variable(_, acc), do: Map.update(acc, :meaningful, 1, &(&1 + 1))

  defp record_not_matching(expected, {name, meta, _}, acc) do
    case {expected, Atom.to_string(name)} do
      {:anonymous, "_" <> rest = trigger} when rest != "" ->
        [[line_no: meta[:line], trigger: trigger] | acc]

      {:meaningful, "_" = trigger} ->
        [[line_no: meta[:line], trigger: trigger] | acc]

      _ ->
        acc
    end
  end
end
