defmodule Credo.Check.Consistency.SpaceInParentheses.Collector do
  @moduledoc false

  use Credo.Check.Consistency.Collector

  def collect_from_source_file(source_file) do
    Credo.Code.Token.reduce(source_file, &spaces(&1, &2, &3, &4), %{})
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

  defp spaces({:%{}, {line_no, col0, _}}, {:"{", {line, col, _}}, {:"}", {line, col2, _}} = _next, acc) do
    # elixir <= 1.16 || elixir > 1.16
    no_space_between? =
      (col0 + 1 == col && col + 1 == col2) ||
        (col0 == col && col + 2 == col2)

    location = [trigger: "%{}", line_no: line_no, column: col0]

    do_spaces(no_space_between?, true, location, acc)
  end

  defp spaces(_prev, {:"[", {line, col, _}}, {:"]", {line, col2, _}} = _next, acc) when col2 - col == 1 do
    do_spaces(true, true, [trigger: "[]", line_no: line, column: col], acc)
  end

  defp spaces(_prev, {:"{", {line, col, _}}, {:"}", {line, col2, _}} = _next, acc) when col2 - col == 1 do
    do_spaces(true, true, [trigger: "{}", line_no: line, column: col], acc)
  end

  # ignores `, ]` at the end of a list
  defp spaces({:",", {line, _col, _}}, {:"]", {line, _col2, _}}, _next, acc), do: acc

  defp spaces({:"[", {line, _col, _}}, {:"]", {line, _col2, _}}, _next, acc), do: acc
  defp spaces({:"(", {line, _col, _}}, {:")", {line, _col2, _}}, _next, acc), do: acc
  defp spaces({:"{", {line, _col, _}}, {:"}", {line, _col2, _}}, _next, acc), do: acc

  defp spaces(_prev, {paren, {_line, _col, _}} = t1, next, acc) when paren in [:"(", :"[", :"{"] do
    {line_no, col_start, _line_no_end, col_end} = Credo.Code.Token.position(t1)
    {line_no2, col_start2, _line_no_end, _col_end} = Credo.Code.Token.position(next)

    empty_enum? =
      case next do
        {:")", _} -> true
        {:"}", _} -> true
        {:"]", _} -> true
        _ -> false
      end

    if Credo.Code.Token.eol?(next) || line_no != line_no2 do
      acc
    else
      no_space_between? = line_no == line_no2 && col_end == col_start2
      location = [trigger: "#{paren}", line_no: line_no, column: col_start]

      do_spaces(no_space_between?, empty_enum?, location, acc)
    end
  end

  defp spaces(prev, {paren, {_, _, _}} = t1, _next, acc) when paren in [:"}", :"]", :")"] do
    {line_no, _col_start, _line_no_end, col_end} = prev |> Credo.Code.Token.position()
    {line_no2, col_start2, _line_no_end, _col_end} = t1 |> Credo.Code.Token.position()

    empty_enum? =
      case prev do
        {:"(", _} -> true
        {:"{", _} -> true
        {:"[", _} -> true
        _ -> false
      end

    if Credo.Code.Token.eol?(prev) || line_no != line_no2 do
      acc
    else
      no_space_between? = col_end == col_start2 || col_end > col_start2
      location = [trigger: "#{paren}", line_no: line_no, column: col_start2]

      do_spaces(no_space_between?, empty_enum?, location, acc)
    end
  end

  defp spaces(_prev, _current, _next, acc), do: acc

  defp do_spaces(no_space_between?, empty_enum?, location, acc) do
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
