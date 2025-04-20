defmodule Credo.Check.Consistency.SpaceInParentheses.Collector do
  @moduledoc false

  use Credo.Check.Consistency.Collector

  def collect_from_source_file(source_file) do
    # Credo.Code.to_tokens(source_file) |> dbg(limit: :infinity)

    # |> dbg
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

  defp spaces({:%{}, {line_no, col0, _}}, {:"{", {line_no, col, _}}, {:"}", {line_no, col2, _}} = _next, acc) do
    # elixir <= 1.16 || elixir > 1.16
    no_space_between? =
      (col0 + 1 == col && col + 1 == col2) ||
        (col0 == col && col + 2 == col2)

    location = [trigger: "%{}", line_no: line_no, column: col0]

    do_spaces(no_space_between?, true, location, acc)
  end

  defp spaces({:%{}, {line_no, col0, _}}, {:"{", {line_no, col, _}}, next, acc) do
    {line_no2, col2, _line_no_end, _col_end} = Credo.Code.Token.position(next)

    no_space_between? =
      if line_no != line_no2 do
        false
      else
        if col0 == col do
          # elixir > 1.16
          col + 1 == col2 - 1
        else
          # elixir <= 1.16
          col == col2 - 1
        end
      end

    location = [trigger: "%{", line_no: line_no, column: col0]

    do_spaces(no_space_between?, false, location, acc)
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

  # there is a "problem" with the tokenizer where control characters are not escaped
  # in the tokenizer; this is a quick and dirty fix to handle that
  defp spaces({:bin_string, {line, col0, nil}, [string]}, {paren, {line, col1, _}}, _next, acc)
       when is_binary(string) and paren in [:"}", :"]", :")"] do
    norm_string =
      string
      |> String.replace("\\", "\\\\", global: true)
      |> String.replace(~r/\n/, "\\n", global: true)
      |> String.replace(~r/\r/, "\\r", global: true)
      |> String.replace(~r/\t/, "\\t", global: true)
      |> String.replace(~r/\"/, "\\\"", global: true)

    col0_end = col0 + String.length(norm_string) + 1

    no_space_between? = col0_end == col1 - 1
    location = [trigger: "#{paren}", line_no: line, column: col1]

    do_spaces(no_space_between?, false, location, acc)
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
