defmodule Credo.Check.Consistency.ExceptionNames.Collector do
  @moduledoc false

  use Credo.Check.Consistency.Collector

  alias Credo.Code.Module
  alias Credo.Code.Name

  def collect_matches(source_file, _params) do
    exception_recorder = &record_exception/2

    Credo.Code.prewalk(source_file, &traverse(exception_recorder, &1, &2), %{})
  end

  def find_locations_not_matching(expected, source_file) do
    location_recorder = &record_not_matching(expected, &1, &2)

    source_file
    |> Credo.Code.prewalk(&traverse(location_recorder, &1, &2), [])
    |> Enum.reverse()
  end

  defp traverse(
         callback,
         {:defmodule, _meta, [{:__aliases__, _, _name_arr}, _arguments]} = ast,
         acc
       ) do
    if Module.exception?(ast) do
      {ast, callback.(ast, acc)}
    else
      {ast, acc}
    end
  end

  defp traverse(_callback, ast, acc), do: {ast, acc}

  defp record_exception(ast, acc) do
    {prefix, suffix} = ast |> Module.name() |> prefix_and_suffix

    acc
    |> Map.update({:prefix, prefix}, 1, &(&1 + 1))
    |> Map.update({:suffix, suffix}, 1, &(&1 + 1))
  end

  defp record_not_matching(expected, {_, meta, _} = ast, acc) do
    exception_name = Module.name(ast)
    {prefix, suffix} = prefix_and_suffix(exception_name)

    # TODO: how is this `case` necessary
    case expected do
      {:prefix, expected_prefix} ->
        if prefix != expected_prefix do
          [[line_no: meta[:line], trigger: exception_name] | acc]
        else
          acc
        end

      {:suffix, expected_suffix} ->
        if suffix != expected_suffix do
          [[line_no: meta[:line], trigger: exception_name] | acc]
        else
          acc
        end
    end
  end

  defp prefix_and_suffix(exception_name) do
    name_list = exception_name |> Name.last() |> Name.split_pascal_case()
    prefix = List.first(name_list)
    suffix = List.last(name_list)

    {prefix, suffix}
  end
end
