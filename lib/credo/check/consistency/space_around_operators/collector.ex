defmodule Credo.Check.Consistency.SpaceAroundOperators.Collector do
  use Credo.Check.Consistency.Collector

  alias Credo.Code
  import Credo.Check.Consistency.SpaceAroundOperators.SpaceHelper,
    only: [operator?: 1, space_between?: 2, no_space_between?: 2, usually_no_space_before?: 3, usually_no_space_after?: 3]

  def collect_matches(source_file, _params) do
    source_file
    |> Code.to_tokens
    |> traverse_tokens(&record_spaces(&1, &2, &3, &4), %{})
  end

  def find_locations_not_matching(expected, source_file) do
    source_file
    |> Code.to_tokens
    |> traverse_tokens(&record_not_matching(expected, &1, &2, &3, &4), [])
    |> Enum.reverse
  end

  defp traverse_tokens(tokens, callback, acc) do
    tokens
    |> skip_function_capture
    |> case do
        [prev | [current | [next | rest]]] ->
          acc =
            if operator?(current) do
              callback.(prev, current, next, acc)
            else
              acc
            end

          traverse_tokens([current | [next | rest]], callback, acc)
        _ ->
          acc
      end
  end

  defp skip_function_capture([{:capture_op, _, _} | tokens]) do
    Enum.drop_while(tokens, fn
      {:atom, _, _} -> true # :erlang_module
      {:aliases, _, _} -> true # ElixirModule
      {:identifier, _, _} -> true # function_name
      {:at_op, _, _} -> true # @module_attribute
      {:., _} -> true
      _ -> false
    end)
  end
  defp skip_function_capture(tokens), do: tokens

  defp record_spaces(prev, current, next, acc) do
    acc
    |> increment(:with_space, with_space?(prev, current, next))
    |> increment(:without_space, without_space?(prev, current, next))
  end

  defp increment(map, key, matches) do
    if matches do
      Map.update(map, key, 1, &(&1 + 1))
    else
      map
    end
  end

  defp record_not_matching(expected, prev, current, next, acc) do
    match_found =
      case expected do
        :with_space ->
          without_space?(prev, current, next)
        :without_space ->
          with_space?(prev, current, next)
      end

    if match_found do
      {_, {line_no, column, _}, trigger} = current

      [[line_no: line_no, column: column, trigger: trigger] | acc]
    else
      acc
    end
  end

  defp with_space?(prev, op, next) do
    space_between?(prev, op) || space_between?(op, next)
  end

  defp without_space?(prev, op, next) do
    !usually_no_space_before?(prev, op, next) && no_space_between?(prev, op)
    || !usually_no_space_after?(prev, op, next) && no_space_between?(op, next) && !(elem(next, 0) == :eol)
  end
end
