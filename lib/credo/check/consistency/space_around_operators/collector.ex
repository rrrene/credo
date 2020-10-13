defmodule Credo.Check.Consistency.SpaceAroundOperators.Collector do
  @moduledoc false

  use Credo.Check.Consistency.Collector

  alias Credo.Code

  import Credo.Check.Consistency.SpaceAroundOperators.SpaceHelper,
    only: [
      operator?: 1,
      space_between?: 2,
      no_space_between?: 2,
      usually_no_space_before?: 3,
      usually_no_space_after?: 3
    ]

  def collect_matches(source_file, _params) do
    source_file
    |> Code.to_tokens()
    |> traverse_tokens(&record_spaces(&1, &2, &3, &4), %{})
  end

  def find_locations_not_matching(expected, source_file) do
    source_file
    |> Code.to_tokens()
    |> traverse_tokens(&record_not_matching(expected, &1, &2, &3, &4), [])
    |> Enum.reverse()
  end

  defp traverse_tokens(tokens, callback, acc) do
    tokens
    |> skip_specs_types_captures_and_binary_patterns()
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

  defp skip_specs_types_captures_and_binary_patterns([{:at_op, {line, _, _}, :@} | tokens]) do
    case tokens do
      # @spec - drop whole line
      [{:identifier, _, :spec} | tokens] ->
        drop_while_on_line(tokens, line)

      # @type - drop whole line
      [{:identifier, _, :type} | tokens] ->
        drop_while_on_line(tokens, line)

      tokens ->
        tokens
    end
  end

  defp skip_specs_types_captures_and_binary_patterns([{:capture_op, _, _} | tokens]) do
    drop_while_in_fun_capture(tokens)
  end

  # When quoting &//2 (which captures the / operator via &fun_name/2), the
  # {:capture_op, _, :&} token becomes an {:identifier, _, :&} token ...
  defp skip_specs_types_captures_and_binary_patterns([
         {:identifier, _, :&} | [{:identifier, _, :/} | tokens]
       ]) do
    drop_while_in_fun_capture(tokens)
  end

  defp skip_specs_types_captures_and_binary_patterns([{:"<<", _} | tokens]) do
    drop_while_in_binary_pattern(tokens)
  end

  defp skip_specs_types_captures_and_binary_patterns(tokens), do: tokens

  defp drop_while_on_line(tokens, line) do
    Enum.drop_while(tokens, fn
      {_, {^line, _, _}} -> true
      {_, {^line, _, _}, _} -> true
      _ -> false
    end)
  end

  defp drop_while_in_fun_capture(tokens) do
    Enum.drop_while(tokens, fn
      # :erlang_module
      {:atom, _, _} ->
        true

      # ElixirModule (Elixir >= 1.6.0)
      {:alias, _, _} ->
        true

      # ElixirModule
      {:aliases, _, _} ->
        true

      # function_name
      {:identifier, _, _} ->
        true

      # unquote
      {:paren_identifier, _, :unquote} ->
        true

      # @module_attribute
      {:at_op, _, _} ->
        true

      {:mult_op, _, :/} ->
        true

      {:., _} ->
        true

      {:"(", _} ->
        true

      {:")", _} ->
        true

      _ ->
        false
    end)
  end

  defp drop_while_in_binary_pattern(tokens) do
    Enum.drop_while(tokens, fn
      :">>" ->
        false

      _ ->
        true
    end)
  end

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
    (!usually_no_space_before?(prev, op, next) && no_space_between?(prev, op)) ||
      (!usually_no_space_after?(prev, op, next) && no_space_between?(op, next) &&
         !(elem(next, 0) == :eol))
  end
end
