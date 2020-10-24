defmodule Credo.Check.Consistency.SpaceAroundOperators.SpaceHelper do
  @moduledoc false

  alias Credo.Code.Token

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
  def usually_no_space_before?({:flt, _, _}, {_, _, :-}, _), do: false
  def usually_no_space_before?(_, {_, _, :-}, _), do: true
  def usually_no_space_before?(_, {_, _, :..}, _), do: true
  def usually_no_space_before?(_, _, _), do: false

  @doc """
  Returns true if there is no space after the operator (usually).

  Examples:
  x..-1   # .. is the operator here and there is usually no space after that
  """
  def usually_no_space_after?({:"(", _}, {:dual_op, _, :-}, {:identifier, _, _}), do: true
  def usually_no_space_after?({:"(", _}, {:dual_op, _, :-}, {:number, _, _}), do: true
  def usually_no_space_after?({:"(", _}, {:dual_op, _, :-}, {:int, _, _}), do: true
  def usually_no_space_after?({:"(", _}, {:dual_op, _, :-}, {:float, _, _}), do: true
  def usually_no_space_after?({:"(", _}, {:dual_op, _, :-}, {:flt, _, _}), do: true
  def usually_no_space_after?({:",", _}, {:dual_op, _, :-}, {:identifier, _, _}), do: true
  def usually_no_space_after?({:",", _}, {:dual_op, _, :-}, {:number, _, _}), do: true
  def usually_no_space_after?({:",", _}, {:dual_op, _, :-}, {:int, _, _}), do: true
  def usually_no_space_after?({:",", _}, {:dual_op, _, :-}, {:float, _, _}), do: true
  def usually_no_space_after?({:",", _}, {:dual_op, _, :-}, {:flt, _, _}), do: true
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
  def operator?({:concat_op, _, _}), do: true
  def operator?({:rel_op, _, _}), do: true
  def operator?({:rel_op2, _, _}), do: true
  def operator?({:and_op, _, _}), do: true
  def operator?({:or_op, _, _}), do: true
  def operator?({:match_op, _, _}), do: true
  def operator?({:in_match_op, _, _}), do: true
  def operator?({:stab_op, _, _}), do: true
  def operator?({:pipe_op, _, _}), do: true
  # Space around |> is ignored
  def operator?({:arrow_op, _, _}), do: false
  def operator?(_), do: false

  def no_space_between?(arg1, arg2) do
    {line_no, _col_start, _line_no_end, col_end} = Token.position(arg1)
    {line_no2, col_start2, _line_no_end, _col_end} = Token.position(arg2)

    line_no == line_no2 && col_end == col_start2
  end

  def space_between?(arg1, arg2) do
    {line_no, _col_start, _line_no_end, col_end} = Token.position(arg1)
    {line_no2, col_start2, _line_no_end, _col_end} = Token.position(arg2)

    line_no == line_no2 && col_end < col_start2
  end
end
