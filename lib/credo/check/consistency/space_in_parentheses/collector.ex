defmodule Credo.Check.Consistency.SpaceInParentheses.Collector do
  @moduledoc false

  use Credo.Check.Consistency.Collector

  def collect_matches(source_file, _params) do
    # dbg(Credo.Code.to_tokens(source_file), limit: :infinity)

    Credo.Code.Token.reduce(source_file, &spaces(&1, &2, &3, &4), %{})
    |> Map.new(fn {key, value} ->
      {key, Enum.count(value)}
    end)
  end

  def find_locations_not_matching(expected, source_file, allow_empty_enums) do
    actual =
      case expected do
        :with_space when allow_empty_enums == true -> :without_space_allow_empty_enums
        :with_space -> :without_space
        :without_space -> :with_space
      end

    Credo.Code.Token.reduce(source_file, &spaces(&1, &2, &3, &4), %{})
    |> Map.get(actual)
    |> List.wrap()
  end

  defp spaces({:%{}, {_, col0, _}}, {:"{", {line, col, _}} = t1, {:"}", {line, col2, _}} = _next, acc) do
    {line_no, col_start, _line_no_end, _col_end} = Credo.Code.Token.position(t1)

    empty_enum? = true

    no_space_between? = col0 == col && col + 2 == col2

    location = [trigger: "%{}", line_no: line_no, column: col_start]

    do_spaces(no_space_between?, empty_enum?, location, acc)
  end

  # ignores `, ]` at the end of a list
  defp spaces({:",", {line, _col, _}}, {:"]", {line, _col2, _}}, _next, acc), do: acc

  defp spaces({:"[", {line, _col, _}}, {:"]", {line, _col2, _}}, _next, acc), do: acc
  defp spaces({:"(", {line, _col, _}}, {:")", {line, _col2, _}}, _next, acc), do: acc
  defp spaces({:"{", {line, _col, _}}, {:"}", {line, _col2, _}}, _next, acc), do: acc

  defp spaces(_prev, {paren, {_line, _col, _}} = t1, next, acc) when paren in [:"(", :"[", :"{"] do
    # dbg(:opening)
    {line_no, col_start, _line_no_end, col_end} = Credo.Code.Token.position(t1)
    # dbg(next)
    {line_no2, col_start2, _line_no_end, _col_end} = Credo.Code.Token.position(next)

    empty_enum? =
      case next do
        {:")", _} -> true
        {:"}", _} -> true
        {:"]", _} -> true
        _ -> false
      end

    no_space_between? = line_no == line_no2 && col_end == col_start2
    location = [trigger: "#{paren}", line_no: line_no, column: col_start]

    do_spaces(no_space_between?, empty_enum?, location, acc)
  end

  defp spaces(prev, {paren, {_, _, _}} = t1, _next, acc) when paren in [:"}", :"]", :")"] do
    # dbg(:closing)

    {line_no, _col_start, _line_no_end, col_end} = Credo.Code.Token.position(prev)
    {line_no2, col_start2, _line_no_end, _col_end} = Credo.Code.Token.position(t1)

    empty_enum? =
      case prev do
        {:"(", _} -> true
        {:"{", _} -> true
        {:"[", _} -> true
        _ -> false
      end

    no_space_between? = line_no == line_no2 && col_end == col_start2
    location = [trigger: "#{paren}", line_no: line_no, column: col_start2]

    do_spaces(no_space_between?, empty_enum?, location, acc)
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
