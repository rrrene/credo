defmodule Credo.Code.Heredocs do
  @moduledoc """
  This module let's you strip heredocs from source code.
  """

  @doc """
  Replaces all characters inside heredocs
  with the equivalent amount of white-space.
  """
  def replace_with_spaces(source, replacement \\ " ") do
    parse_code(source, "", replacement)
  end

  defp parse_code("", acc, _replacement) do
    acc
  end
  defp parse_code(<< "\\\""::utf8, t::binary >>, acc, replacement) do
    parse_code(t, acc <> "\\\"", replacement)
  end
  defp parse_code(<< "?\""::utf8, t::binary >>, acc, replacement) do
    parse_code(t, acc <> "?\"", replacement)
  end
  defp parse_code(<< "\"\"\""::utf8, t::binary >>, acc, replacement) do
    parse_heredoc(t, acc <> ~s("""), replacement)
  end
  defp parse_code(<< "\'\'\'"::utf8, t::binary >>, acc, replacement) do
    parse_heredoc(t, acc <> ~s("""), replacement)
  end
  defp parse_code(<< h::utf8, t::binary >>, acc, replacement) do
    parse_code(t, acc <> <<h :: utf8>>, replacement)
  end
  defp parse_code(str, acc, replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)

    parse_code(t, acc <> h, replacement)
  end


  defp parse_heredoc("", acc, _replacement) do
    acc
  end
  defp parse_heredoc(<< "\\\\"::utf8, t::binary >>, acc, replacement) do
    parse_heredoc(t, acc, replacement)
  end
  defp parse_heredoc(<< "\\\""::utf8, t::binary >>, acc, replacement) do
    parse_heredoc(t, acc, replacement)
  end
  defp parse_heredoc(<< "\"\"\""::utf8, t::binary >>, acc, replacement) do
    parse_code(t, acc <> ~s("""), replacement)
  end
  defp parse_heredoc(<< "\n"::utf8, t::binary >>, acc, replacement) do
    parse_heredoc(t, acc <> "\n", replacement)
  end
  defp parse_heredoc(<< _::utf8, t::binary >>, acc, replacement) do
    parse_heredoc(t, acc <> replacement, replacement)
  end
end
