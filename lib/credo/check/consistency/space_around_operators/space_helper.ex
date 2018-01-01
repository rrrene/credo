defmodule Credo.Check.Consistency.SpaceAroundOperators.SpaceHelper do
  @doc """
  Returns true if there is no space before the operator (usually).

  Examples:
  x..-1   # .. is the operator here and there is usually no space before that
  """
  def usually_no_space_before?({_, _, :^}, {_, _, :-}, _), do: true
  def usually_no_space_before?({:identifier, _, _}, {_, _, :-}, _), do: false
  def usually_no_space_before?({:number, _, _}, {_, _, :-}, _), do: false
  def usually_no_space_before?({:int, _, _}, {_, _, :-}, _), do: false
  def usually_no_space_before?({:float, _, _}, {_, _, :-}, _), do: false
  def usually_no_space_before?(_, {_, _, :-}, _), do: true
  def usually_no_space_before?(_, {_, _, :..}, _), do: true
  def usually_no_space_before?(_, _, _), do: false

  @doc """
  Returns true if there is no space after the operator (usually).

  Examples:
  x..-1   # .. is the operator here and there is usually no space before that
  """
  def usually_no_space_after?({_, _, :^}, {_, _, :-}, _), do: true
  def usually_no_space_after?({_, _, :=}, {_, _, :-}, _), do: true
  def usually_no_space_after?({_, _, :..}, {_, _, :-}, _), do: true
  def usually_no_space_after?(_, {_, _, :-}, _), do: false
  def usually_no_space_after?(_, {_, _, :..}, _), do: true
  def usually_no_space_after?(_, _, _), do: false

  def operator?({:comp_op, _, _}), do: true
  def operator?({:comp_op2, _, _}), do: true
  def operator?({:dual_op, _, _}), do: true
  def operator?({:mult_op, _, _}), do: true
  def operator?({:two_op, _, _}), do: true
  def operator?({:arrow_op, _, _}), do: true
  def operator?({:rel_op, _, _}), do: true
  def operator?({:rel_op2, _, _}), do: true
  def operator?({:and_op, _, _}), do: true
  def operator?({:or_op, _, _}), do: true
  def operator?({:match_op, _, _}), do: true
  def operator?({:in_match_op, _, _}), do: true
  def operator?({:stab_op, _, _}), do: true
  def operator?({:pipe_op, _, _}), do: true
  def operator?(_), do: false

  def no_space_between?(arg1, arg2) do
    {line_no, _col_start, col_end} = position(arg1)
    {line_no2, col_start2, _col_end} = position(arg2)

    line_no == line_no2 && col_end == col_start2
  end

  def space_between?(arg1, arg2) do
    {line_no, _col_start, col_end} = position(arg1)
    {line_no2, col_start2, _col_end} = position(arg2)

    line_no == line_no2 && col_end < col_start2
  end

  if Version.match?(System.version, "< 1.6.0") do
    defp position({_, pos, _, _, _, _}), do: pos
    defp position({_, pos, _, _, _}), do: pos
    defp position({_, pos, _, _}), do: pos
    defp position({_, pos, _}), do: pos
    defp position({_, pos}), do: pos
  else
    # Elixir >= 1.6.0
    defp position({_, {line_no, col_start, _}, atom_or_charlist, _, _, _}) do
      position_tuple(atom_or_charlist, line_no, col_start)
    end
    defp position({_, {line_no, col_start, _}, atom_or_charlist, _, _}) do
      position_tuple(atom_or_charlist, line_no, col_start)
    end
    defp position({_, {line_no, col_start, _}, atom_or_charlist, _}) do
      position_tuple(atom_or_charlist, line_no, col_start)
    end
    defp position({_, {line_no, col_start, _}, atom_or_charlist}) do
      position_tuple(atom_or_charlist, line_no, col_start)
    end
    defp position({atom_or_charlist, {line_no, col_start, _}}) do
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
  end
end
