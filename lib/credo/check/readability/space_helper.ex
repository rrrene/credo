defmodule Credo.Check.Readability.SpaceHelper do
  alias Credo.Code.Token

  def expected_spaces({:pipe_op, _, _}), do: :with_space
  def expected_spaces(_), do: :ignore

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
