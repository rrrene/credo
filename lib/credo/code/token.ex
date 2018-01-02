defmodule Credo.Code.Token do
  @moduledoc """
  This module provides helper functions to analyse tokens.
  """

  if Version.match?(System.version, ">= 1.6.0-rc") do
    # Elixir >= 1.6.0
    def position({_, {line_no, col_start, _}, atom_or_charlist, _, _, _}) do
      position_tuple(atom_or_charlist, line_no, col_start)
    end
    def position({_, {line_no, col_start, _}, atom_or_charlist, _, _}) do
      position_tuple(atom_or_charlist, line_no, col_start)
    end
    def position({_, {line_no, col_start, _}, atom_or_charlist, _}) do
      position_tuple(atom_or_charlist, line_no, col_start)
    end
    def position({_, {line_no, col_start, _}, atom_or_charlist}) do
      position_tuple(atom_or_charlist, line_no, col_start)
    end
    def position({atom_or_charlist, {line_no, col_start, _}}) do
      position_tuple(atom_or_charlist, line_no, col_start)
    end

    defp position_tuple(atom_or_charlist, line_no, col_start) when is_atom(atom_or_charlist) or is_list(atom_or_charlist) do
      binary = to_string(atom_or_charlist)
      col_end = col_start + String.length(binary)

      {line_no, col_start, col_end}
    end
    defp position_tuple(number, line_no, col_start) when is_number(number) do
      binary = to_string([number])
      col_end = col_start + String.length(binary)

      {line_no, col_start, col_end}
    end
    defp position_tuple(_, _line_no, _col_start), do: nil
  else
    def position({_, pos, _, _, _, _}), do: pos
    def position({_, pos, _, _, _}), do: pos
    def position({_, pos, _, _}), do: pos
    def position({_, pos, _}), do: pos
    def position({_, pos}), do: pos
  end
end
