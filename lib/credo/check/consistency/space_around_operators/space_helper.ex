defmodule Credo.Check.Consistency.SpaceAroundOperators.SpaceHelper do
  @doc """
  Returns true if there is no space before the operator (usually).

  Examples:
  x..-1   # .. is the operator here and there is usually no space before that
  """
  def usually_no_space_before?({_, _, :^}, {_, _, :-}, _), do: true
  def usually_no_space_before?({:identifier, _, _}, {_, _, :-}, _), do: false
  def usually_no_space_before?({:number, _, _}, {_, _, :-}, _), do: false
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

  def position({_, pos, _, _, _, _}), do: pos
  def position({_, pos, _, _, _}), do: pos
  def position({_, pos, _, _}), do: pos
  def position({_, pos, _}), do: pos
  def position({_, pos}), do: pos
end
