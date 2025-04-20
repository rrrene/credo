defmodule Credo.Code.Token do
  @moduledoc """
  This module provides helper functions to analyse tokens returned by `Credo.Code.to_tokens/1`.
  """

  @doc """
  Returns `true` if the given `token` contains a line break.
  """
  def eol?(token)

  def eol?(list) when is_list(list) do
    Enum.any?(list, &eol?/1)
  end

  def eol?({_, {_, _, _}, _, list, _, _}) when is_list(list) do
    Enum.any?(list, &eol?/1)
  end

  def eol?({_, {_, _, _}, list}) when is_list(list) do
    Enum.any?(list, &eol?/1)
  end

  def eol?({{_, _, _}, list}) when is_list(list) do
    Enum.any?(list, &eol?/1)
  end

  def eol?({:eol, {_, _, _}}), do: true
  def eol?(_), do: false

  @doc """
  Returns the position of a token in the form

      {line_no_start, col_start, line_no_end, col_end}
  """
  def position(token)

  def position({_, {line_no, col_start, _}, atom_or_charlist, _, _, _}) do
    position_tuple(atom_or_charlist, line_no, col_start)
  end

  def position({_, {line_no, col_start, _}, atom_or_charlist, _, _}) do
    position_tuple(atom_or_charlist, line_no, col_start)
  end

  def position({_, {line_no, col_start, _}, atom_or_charlist, _}) do
    position_tuple(atom_or_charlist, line_no, col_start)
  end

  def position({:bin_string, {line_no, col_start, _}, atom_or_charlist}) do
    position_tuple_for_quoted_string(atom_or_charlist, line_no, col_start)
  end

  def position({:list_string, {line_no, col_start, _}, atom_or_charlist}) do
    position_tuple_for_quoted_string(atom_or_charlist, line_no, col_start)
  end

  def position({:bin_heredoc, {line_no, col_start, _}, atom_or_charlist}) do
    position_tuple_for_heredoc(atom_or_charlist, line_no, col_start)
  end

  def position({:list_heredoc, {line_no, col_start, _}, atom_or_charlist}) do
    position_tuple_for_heredoc(atom_or_charlist, line_no, col_start)
  end

  def position({:char, {line_no, col_start, charlist}, _number}) when is_list(charlist) do
    col_end = col_start + String.length(to_string(charlist))

    {line_no, col_start, line_no, col_end}
  end

  def position({:atom, {line_no, col_start, nil}, atom}) do
    # +1 for the `:` of the atom
    col_end = col_start + String.length(to_string(atom)) + 1

    {line_no, col_start, line_no, col_end}
  end

  def position({:atom, {line_no, col_start, atom_or_charlist}, _atom}) do
    # +1 for the `:` of the atom
    col_end = col_start + String.length(to_string(atom_or_charlist)) + 1

    {line_no, col_start, line_no, col_end}
  end

  def position({:atom_unsafe, {line_no, col_start, _}, atom_or_charlist}) do
    position_tuple_for_quoted_string(atom_or_charlist, line_no, col_start)
  end

  def position({:atom_quoted, {line_no, col_start, _}, atom_or_charlist}) do
    # +1 for the `:` of the atom and 2 for the quotes
    col_end = col_start + String.length(to_string(atom_or_charlist)) + 1 + 2

    {line_no, col_start, line_no, col_end}
  end

  # Elixir >= 1.10.0 tuple syntax
  def position({:sigil, {line_no, col_start, nil}, sigil_name, charlist, modifiers, _number, _binary})
      when is_list(charlist) do
    case position_tuple_for_quoted_string(charlist, line_no, col_start) do
      {line1, col_start, line1, col_end} ->
        sigil_tag = String.replace("~#{sigil_name}", ~r/sigil_/, "")

        {line1, col_start, line1, col_end + String.length(sigil_tag) + String.length(to_string(modifiers))}

      value ->
        value
    end
  end

  # Elixir >= 1.9.0 tuple syntax
  def position({{line_no, col_start, nil}, {_line_no2, _col_start2, nil}, atom_or_charlist}) do
    position_tuple_for_quoted_string(atom_or_charlist, line_no, col_start)
  end

  def position({:kw_identifier_unsafe, {line_no, col_start, _}, atom_or_charlist})
      when is_atom(atom_or_charlist) or is_list(atom_or_charlist) do
    position_tuple_for_quoted_string(atom_or_charlist, line_no, col_start)
  end

  # Elixir < 1.9.0 tuple syntax
  def position({_, {line_no, col_start, _}, atom_or_charlist}) do
    position_tuple(atom_or_charlist, line_no, col_start)
  end

  def position({nil, {line_no, col_start, nil}}) do
    {line_no, col_start, line_no, col_start + 3}
  end

  def position({atom_or_charlist, {line_no, col_start, _}}) do
    position_tuple(atom_or_charlist, line_no, col_start)
  end

  # interpolation
  def position({{line_no, col_start, _}, list}) when is_list(list) do
    {line_no, col_start, line_no_end, col_end} =
      position_tuple_for_quoted_string(list, line_no, col_start)

    {line_no, col_start, line_no_end, col_end}
  end

  #

  defp position_tuple(list, line_no, col_start) when is_list(list) do
    binary = to_string(list)
    col_end = col_start + String.length(binary)

    {line_no, col_start, line_no, col_end}
  end

  defp position_tuple(atom, line_no, col_start) when is_atom(atom) do
    binary = to_string(atom)
    col_end = col_start + String.length(binary)

    {line_no, col_start, line_no, col_end}
  end

  defp position_tuple(number, line_no, col_start) when is_number(number) do
    binary = to_string([number])
    col_end = col_start + String.length(binary)

    {line_no, col_start, line_no, col_end}
  end

  defp position_tuple(_, _line_no, _col_start), do: nil

  defp position_tuple_for_heredoc(list, line_no, col_start)
       when is_list(list) do
    # add 3 for """ (closing double quote)
    {line_no_end, col_end, _terminator} = convert_to_col_end(line_no, col_start, list)

    col_end = col_end + 3

    {line_no, col_start, line_no_end, col_end}
  end

  @doc false
  def position_tuple_for_quoted_string([string], line_no, col_start)
      when is_binary(string) do
    # a simple string with double quotes (note the brackets in the fun head match)
    case String.split(string, "\n") do
      [string] ->
        # no line break
        col_end = col_start + String.length(string) + 2

        {line_no, col_start, line_no, col_end}

      [_ | _] = list ->
        # line breaks
        newlines = Enum.count(list) - 1
        last_line = List.last(list)

        {line_no_end, col_end, terminator} = convert_to_col_end(line_no + newlines, 1, last_line)

        {line_no_end, col_end} =
          case terminator do
            :eol ->
              # move to next line
              {line_no_end + 1, 1}

            _ ->
              # add 1 for " (closing double quote)
              {line_no_end, col_end + 1}
          end

        {line_no, col_start, line_no_end, col_end}
    end
  end

  def position_tuple_for_quoted_string(atom_or_charlist, line_no, col_start)
      when is_list(atom_or_charlist) or is_atom(atom_or_charlist) do
    {line_no_end, col_end, terminator} = convert_to_col_end(line_no, col_start, atom_or_charlist)

    {line_no_end, col_end} =
      case terminator do
        :eol ->
          # move to next line
          {line_no_end + 1, 1}

        _ ->
          # add 1 for " (closing double quote)
          {line_no_end, col_end + 1}
      end

    {line_no, col_start, line_no_end, col_end}
  end

  #

  defp convert_to_col_end(line_no, col_start, list) when is_list(list) do
    Enum.reduce(list, {line_no, col_start, nil}, &reduce_to_col_end/2)
  end

  # Elixir < 1.9.0
  #
  # {{1, 25, 32}, [{:identifier, {1, 27, 31}, :name}]}
  defp convert_to_col_end(_, _, {{line_no, col_start, _}, list}) do
    {line_no_end, col_end, _terminator} = convert_to_col_end(line_no, col_start, list)

    # add 1 for } (closing parens of interpolation)
    col_end = col_end + 1

    {line_no_end, col_end, :interpolation}
  end

  # Elixir >= 1.9.0
  #
  # {{1, 25, nil}, {1, 31, nil}, [{:identifier, {1, 27, nil}, :name}]}
  defp convert_to_col_end(
         _,
         _,
         {{line_no, col_start, nil}, {_line_no2, _col_start2, nil}, list}
       ) do
    {line_no_end, col_end, _terminator} = convert_to_col_end(line_no, col_start, list)

    # add 1 for } (closing parens of interpolation)
    col_end = col_end + 1

    {line_no_end, col_end, :interpolation}
  end

  defp convert_to_col_end(_, _, {:eol, {line_no, col_start, _}}) do
    {line_no, col_start, :eol}
  end

  defp convert_to_col_end(_, _, {value, {line_no, col_start, _}}) do
    {line_no, to_col_end(col_start, value), nil}
  end

  defp convert_to_col_end(_, _, {:bin_string, {line_no, col_start, nil}, list})
       when is_list(list) do
    # add 2 for opening and closing "
    {line_no, col_end, terminator} =
      Enum.reduce(list, {line_no, col_start, nil}, &reduce_to_col_end/2)

    {line_no, col_end + 2, terminator}
  end

  defp convert_to_col_end(_, _, {:bin_string, {line_no, col_start, nil}, value}) do
    # add 2 for opening and closing "
    {line_no, to_col_end(col_start, value, 2), :bin_string}
  end

  defp convert_to_col_end(_, _, {:list_string, {line_no, col_start, nil}, value}) do
    # add 2 for opening and closing '
    {line_no, to_col_end(col_start, value, 2), :bin_string}
  end

  defp convert_to_col_end(_, _, {_, {line_no, col_start, nil}, list})
       when is_list(list) do
    Enum.reduce(list, {line_no, col_start, nil}, &reduce_to_col_end/2)
  end

  defp convert_to_col_end(_, _, {_, {line_no, col_start, nil}, value}) do
    {line_no, to_col_end(col_start, value), nil}
  end

  defp convert_to_col_end(_, _, {:aliases, {line_no, col_start, _}, list}) do
    value = Enum.map(list, &to_string/1)

    {line_no, to_col_end(col_start, value), nil}
  end

  defp convert_to_col_end(_, _, {_, {line_no, col_start, _}, value}) do
    {line_no, to_col_end(col_start, value), nil}
  end

  defp convert_to_col_end(_, _, {:sigil, {line_no, col_start, nil}, _, list, _, _})
       when is_list(list) do
    Enum.reduce(list, {line_no, col_start, nil}, &reduce_to_col_end/2)
  end

  # Elixir >= 1.11
  defp convert_to_col_end(
         _,
         _,
         {:sigil, {line_no, col_start, nil}, _, list, _modifiers, _number, _binary}
       )
       when is_list(list) do
    Enum.reduce(list, {line_no, col_start, nil}, &reduce_to_col_end/2)
  end

  defp convert_to_col_end(_, _, {:sigil, {line_no, col_start, nil}, _, value, _, _}) do
    {line_no, to_col_end(col_start, value), nil}
  end

  defp convert_to_col_end(line_no, col_start, value) do
    {line_no, to_col_end(col_start, value), nil}
  end

  #

  defp reduce_to_col_end(value, {current_line_no, current_col_start, _}) do
    convert_to_col_end(current_line_no, current_col_start, value)
  end

  #

  def to_col_end(col_start, value, add \\ 0) do
    col_start + String.length(to_string(value)) + add
  end

  @doc false
  def reduce(string_or_source_file, callback, acc \\ [])

  def reduce(string_or_source_file, callback, acc) do
    string_or_source_file
    |> Credo.Code.to_tokens()
    |> do_reduce(callback, acc)
  end

  defp do_reduce([], _callback, acc), do: acc

  defp do_reduce([prev | [current | [next | rest]]], callback, acc) do
    acc = callback.(prev, current, next, acc)

    do_reduce([current | [next | rest]], callback, acc)
  end

  defp do_reduce(_tokens, _callback, acc), do: acc
end
