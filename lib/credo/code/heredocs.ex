defmodule Credo.Code.Heredocs do
  @moduledoc """
  This module lets you strip heredocs from source code.
  """

  alias Credo.Code.InterpolationHelper

  @doc """
  Replaces all characters inside heredocs
  with the equivalent amount of white-space.
  """
  def replace_with_spaces(
        source,
        replacement \\ " ",
        interpolation_replacement \\ " ",
        empty_line_replacement \\ ""
      ) do
    source
    |> InterpolationHelper.replace_interpolations(interpolation_replacement)
    |> parse_code("", replacement, empty_line_replacement)
  end

  defp parse_code("", acc, _replacement, _empty_line_replacement) do
    acc
  end

  defp parse_code(<<"\\\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> "\\\"", replacement, empty_line_replacement)
  end

  defp parse_code(<<"?\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> "?\"", replacement, empty_line_replacement)
  end

  defp parse_code(<<"\"\"\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_heredoc(t, acc <> ~s("""), replacement, empty_line_replacement)
  end

  defp parse_code(<<"\'\'\'"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_heredoc(t, acc <> ~s('''), replacement, empty_line_replacement)
  end

  defp parse_code(<<h::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> <<h::utf8>>, replacement, empty_line_replacement)
  end

  defp parse_code(str, acc, replacement, empty_line_replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)

    parse_code(t, acc <> h, replacement, empty_line_replacement)
  end

  defp parse_heredoc("", acc, _replacement, _empty_line_replacement) do
    acc
  end

  defp parse_heredoc(<<"\\\\"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_heredoc(t, acc, replacement, empty_line_replacement)
  end

  defp parse_heredoc(<<"\\\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_heredoc(t, acc, replacement, empty_line_replacement)
  end

  defp parse_heredoc(<<"\"\"\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> ~s("""), replacement, empty_line_replacement)
  end

  defp parse_heredoc(<<"\'\'\'"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> ~s('''), replacement, empty_line_replacement)
  end

  defp parse_heredoc(<<"\n"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    end_of_empty_line? = String.slice(acc, -1..-1) == "\n"

    acc =
      if end_of_empty_line? do
        acc <> empty_line_replacement
      else
        acc
      end

    parse_heredoc(t, acc <> "\n", replacement, empty_line_replacement)
  end

  defp parse_heredoc(<<_::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_heredoc(t, acc <> replacement, replacement, empty_line_replacement)
  end
end
