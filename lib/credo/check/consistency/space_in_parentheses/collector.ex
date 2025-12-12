defmodule Credo.Check.Consistency.SpaceInParentheses.Collector do
  @moduledoc false

  use Credo.Check.Consistency.Collector

  import CredoTokenizer.Guards

  def collect_from_source_file(source_file) do
    # source_file |> Credo.SourceFile.source() |> CredoTokenizer.tokenize() |> dbg(limit: :infinity)

    Credo.Code.Token.reduce(source_file, &collect(&1, &2, &3, &4), %{})
    # |> dbg
  end

  def collect_matches(source_file, _params) do
    collection = collect_from_source_file(source_file)

    Map.new(collection, fn {key, value} ->
      {key, Enum.count(value)}
    end)
  end

  def find_locations_not_matching(expected, source_file, allow_empty_enums) do
    collection = collect_from_source_file(source_file)

    actual =
      case expected do
        :with_space when allow_empty_enums == true -> :without_space_allow_empty_enums
        :with_space -> :without_space
        :without_space -> :with_space
      end

    collection
    |> Map.get(actual)
    |> List.wrap()
  end

  # empty map
  defp collect(
         {{:%{}, nil}, {line, col, _, _}, _, _} = left,
         {{:"{", nil}, {_, _, _, _}, _, _},
         {{:"}", nil}, {_, _, _, _}, _, _} = right,
         acc
       ) do
    location = [trigger: "%{}", line_no: line, column: col]

    do_collect(no_space_between(left, right), true, location, acc)
  end

  # map
  defp collect({{:%{}, nil}, {line, col, _, _}, _, _} = left, {{:"{", nil}, {_, _, _, _}, _, _}, right, acc) do
    location = [trigger: "%{", line_no: line, column: col]

    do_collect(no_space_between(left, right), false, location, acc)
  end

  # paren and paren
  defp collect(_prev, {_, {line, col, _, _}, value, _} = left, right, acc)
       when is_same_line(left, right) and is_opening_paren(left) and is_closing_paren(right) do
    trigger =
      case value do
        "(" -> "()"
        "[" -> "[]"
        "{" -> "{}"
      end

    do_collect(no_space_between(left, right), true, [trigger: trigger, line_no: line, column: col], acc)
  end

  # paren and non-paren/non-eol
  defp collect(_prev, {_, {line, col, _, _}, value, _} = left, right, acc)
       when is_same_line(left, right) and is_opening_paren(left) and not is_eol(right) do
    do_collect(no_space_between(left, right), false, [trigger: value, line_no: line, column: col], acc)
  end

  # `, ]`
  defp collect({{:",", nil}, {_, _, _, _}, _, _} = left, {{:"]", nil}, {_, _, _, _}, _, _} = right, _next, acc)
       when is_same_line(left, right) do
    acc
  end

  # non-paren/non-eol and paren
  defp collect(left, {_, {line, col, _, _}, value, _} = right, _next, acc)
       when is_same_line(left, right) and not is_opening_paren(left) and not is_eol(left) and is_closing_paren(right) do
    do_collect(no_space_between(left, right), false, [trigger: value, line_no: line, column: col], acc)
  end

  defp collect(_prev, _current, _next, acc), do: acc

  defp do_collect(no_space_between?, empty_enum?, location, acc) do
    if no_space_between? do
      if empty_enum? do
        Map.update(acc, :without_space, [location], &[location | &1])
      else
        acc
        |> Map.update(:without_space, [location], &[location | &1])
        |> Map.update(:without_space_allow_empty_enums, [location], &[location | &1])
      end
    else
      Map.update(acc, :with_space, [location], &[location | &1])
    end
  end
end
