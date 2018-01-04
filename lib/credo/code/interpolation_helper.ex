defmodule Credo.Code.InterpolationHelper do
  @moduledoc false

  alias Credo.Code.Token

  @doc false
  def replace_interpolations(source, char \\ " ") do
    positions = interpolation_positions(source)
    lines = String.split(source, "\n")

    positions
    |> Enum.reduce(lines, &replace_line(&1, &2, char))
    |> Enum.join("\n")
  end

  defp replace_line({line_no, col_start, col_end}, lines, char) do
    List.update_at(
      lines,
      line_no - 1,
      &replace_line(&1, col_start, col_end, char)
    )
  end

  defp replace_line(line, col_start, col_end, char) do
    length = max(col_end - col_start, 0)

    String.slice(line, 0, col_start - 1) <>
      String.duplicate(char, length) <> String.slice(line, (col_end - 1)..-1)
  end

  @doc false
  def interpolation_positions(source) do
    source
    |> Credo.Code.to_tokens()
    |> Enum.flat_map(&map_interpolations(&1, source))
    |> Enum.reject(&is_nil/1)
  end

  if Version.match?(System.version(), ">= 1.6.0-rc") do
    #
    # Elixir >= 1.6.0
    #

    defp map_interpolations(
           {:sigil, {_line_no, _col_start, nil}, _, list, _, _sigil_start_char} =
             token,
           source
         ) do
      handle_atom_string_or_sigil(token, list, source)
    end

    defp map_interpolations(
           {:bin_heredoc, {_line_no, _col_start, _}, _list} = token,
           source
         ) do
      handle_heredoc(token, source)
    end

    defp map_interpolations(
           {:bin_string, {_line_no, _col_start, _}, list} = token,
           source
         ) do
      handle_atom_string_or_sigil(token, list, source)
    end
  else
    #
    # Elixir <= 1.5.x
    #

    defp map_interpolations(
           {:sigil, {_line_no, _col_start, _col_end}, _, list, _} = token,
           source
         ) do
      handle_atom_string_or_sigil(token, list, source)
    end

    defp map_interpolations(
           {:bin_string, {line_no, _col_start, _}, list} = token,
           source
         ) do
      if is_sigil_in_line(source, line_no) do
        handle_heredoc(token, source)
      else
        handle_atom_string_or_sigil(token, list, source)
      end
    end

    defp is_sigil_in_line(source, line_no) do
      line_with_heredoc_quotes = get_line(source, line_no)

      !!Regex.run(~r/("""|''')/, line_with_heredoc_quotes)
    end
  end

  defp map_interpolations(
         {:atom_unsafe, {_line_no, _col_start, _}, list} = token,
         source
       ) do
    handle_atom_string_or_sigil(token, list, source)
  end

  defp map_interpolations(_, _source), do: []

  defp handle_atom_string_or_sigil(_token, list, source) do
    find_interpolations(list, source)
  end

  defp handle_heredoc({_atom, {line_no, _, _}, list}, source) do
    first_line_in_heredoc = get_line(source, line_no + 1)

    # TODO: this seems to be wrong. the closing """ determines the
    #       indentation, not the first line of the heredoc.
    padding_in_first_line =
      determine_padding_at_start_of_line(first_line_in_heredoc)

    find_interpolations(list, source)
    |> Enum.reject(&is_nil/1)
    |> add_to_col_start_and_end(padding_in_first_line)
  end

  defp find_interpolations(value, source) when is_list(value) do
    Enum.map(value, &find_interpolations(&1, source))
  end

  # {{1, 25, 32}, [{:identifier, {1, 27, 31}, :name}]}
  defp find_interpolations({{_line_no, _col_start2, _}, _list} = token, source) do
    {line_no, col_start, col_end} = Token.position(token)

    line = get_line(source, line_no)

    # `col_end - 1` to account for the closing `}`
    rest_of_line = get_rest_of_line(line, col_end - 1)

    padding = determine_padding_at_start_of_line(rest_of_line)

    {line_no, col_start, col_end + padding}
  end

  defp find_interpolations(_value, _source), do: nil

  defp determine_padding_at_start_of_line(line) do
    ~r/^\s+/
    |> Regex.run(line)
    |> List.wrap()
    |> Enum.join()
    |> String.length()
  end

  defp add_to_col_start_and_end(positions, padding) do
    Enum.map(positions, fn {line_no, col_start, col_end} ->
      {line_no, col_start + padding, col_end + padding}
    end)
  end

  defp get_line(source, line_no) do
    source
    |> String.split("\n")
    |> Enum.at(line_no - 1)
  end

  defp get_rest_of_line(line, col_end) do
    # col-1 to account for col being 1-based
    String.slice(line, (col_end - 1)..-1)
  end
end
