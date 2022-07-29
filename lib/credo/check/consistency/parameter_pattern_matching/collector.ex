defmodule Credo.Check.Consistency.ParameterPatternMatching.Collector do
  @moduledoc false

  use Credo.Check.Consistency.Collector

  def collect_matches(source_file, _params) do
    position_recorder = &record_position/4

    Credo.Code.prewalk(source_file, &traverse(position_recorder, &1, &2), %{})
  end

  def find_locations_not_matching(expected, source_file) do
    location_recorder = &record_not_matching(expected, &1, &2, &3, &4)

    source_file
    |> Credo.Code.prewalk(&traverse(location_recorder, &1, &2), [])
    |> Enum.reverse()
  end

  def actual_for(:before = _expected), do: :after
  def actual_for(:after = _expected), do: :before

  defp traverse(callback, {:def, _, [{_name, _, params}, _]} = ast, acc)
       when is_list(params) do
    {ast, traverse_params(callback, params, acc)}
  end

  defp traverse(callback, {:defp, _, [{_name, _, params}, _]} = ast, acc)
       when is_list(params) do
    {ast, traverse_params(callback, params, acc)}
  end

  defp traverse(_callback, ast, acc), do: {ast, acc}

  defp traverse_params(callback, params, acc) do
    Enum.reduce(params, acc, fn
      {:=, _, [{capture_name, meta, nil}, _rhs]}, param_acc ->
        callback.(:before, capture_name, meta, param_acc)

      {:=, _, [_lhs, {capture_name, meta, nil}]}, param_acc ->
        callback.(:after, capture_name, meta, param_acc)

      _, param_acc ->
        param_acc
    end)
  end

  defp record_position(kind, _capture_name, _meta, acc) do
    Map.update(acc, kind, 1, &(&1 + 1))
  end

  defp record_not_matching(expected, actual, capture_name, meta, acc) do
    if actual != expected do
      [[line_no: meta[:line], trigger: capture_name] | acc]
    else
      acc
    end
  end
end
