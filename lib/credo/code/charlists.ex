defmodule Credo.Code.Charlists do
  @moduledoc """
  This module let's you strip charlists from source code.
  """

  @doc """
  Replaces all characters inside charlists with the equivalent amount of
  white-space.
  """
  def replace_with_spaces(source, replacement \\ " ") do
    parse_code(source, "", replacement)
  end

  defp parse_code("", acc, _replacement) do
    acc
  end
  defp parse_code(<< "\\\'"::utf8, t::binary >>, acc, replacement) do
    parse_code(t, acc <> "\\\'", replacement)
  end
  defp parse_code(<< "?'"::utf8, t::binary >>, acc, replacement) do
    parse_code(t, acc <> "?'", replacement)
  end
  defp parse_code(<< "'"::utf8, t::binary >>, acc, replacement) do
    parse_charlist(t, acc <> "'", replacement)
  end
  defp parse_code(<< "#"::utf8, t::binary >>, acc, replacement) do
    parse_comment(t, acc <> "#", replacement)
  end
  defp parse_code(<< "\"\"\""::utf8, t::binary >>, acc, replacement) do
    parse_heredoc(t, acc <> ~s("""), replacement)
  end
  defp parse_code(<< "\""::utf8, t::binary >>, acc, replacement) do
    parse_string_literal(t, acc <> "\"", replacement)
  end
  defp parse_code(<< h::utf8, t::binary >>, acc, replacement) do
    parse_code(t, acc <> <<h :: utf8>>, replacement)
  end
  defp parse_code(str, acc, replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)

    parse_code(t, acc <> h, replacement)
  end

  defp parse_comment("", acc, _replacement) do
    acc
  end
  defp parse_comment(<< "\n"::utf8, t::binary >>, acc, replacement) do
    parse_code(t, acc <> "\n", replacement)
  end
  defp parse_comment(str, acc, replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)

    parse_comment(t, acc <> h, replacement)
  end

  defp parse_string_literal("", acc, _replacement) do
    acc
  end
  defp parse_string_literal(<< "\\\\"::utf8, t::binary >>, acc, replacement) do
    parse_string_literal(t, acc, replacement)
  end
  defp parse_string_literal(<< "\\\""::utf8, t::binary >>, acc, replacement) do
    parse_string_literal(t, acc, replacement)
  end
  defp parse_string_literal(<< "\""::utf8, t::binary >>, acc, replacement) do
    parse_code(t, acc <> ~s("), replacement)
  end
  defp parse_string_literal(<< "\n"::utf8, t::binary >>, acc, replacement) do
    parse_string_literal(t, acc <> "\n", replacement)
  end
  defp parse_string_literal(str, acc, replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)
    parse_string_literal(t, acc <> h, replacement)
  end

  defp parse_charlist("", acc, _replacement) do
    acc
  end
  defp parse_charlist(<< "\\\\"::utf8, t::binary >>, acc, replacement) do
    parse_charlist(t, acc, replacement)
  end
  defp parse_charlist(<< "\\\'"::utf8, t::binary >>, acc, replacement) do
    parse_charlist(t, acc, replacement)
  end
  defp parse_charlist(<< "\'"::utf8, t::binary >>, acc, replacement) do
    parse_code(t, acc <> "'", replacement)
  end
  defp parse_charlist(<< "\n"::utf8, t::binary >>, acc, replacement) do
    parse_charlist(t, acc <> "\n", replacement)
  end
  defp parse_charlist(<< _::utf8, t::binary >>, acc, replacement) do
    parse_charlist(t, acc <> replacement, replacement)
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
  defp parse_heredoc(str, acc, replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)
    parse_heredoc(t, acc <> h, replacement)
  end
end
