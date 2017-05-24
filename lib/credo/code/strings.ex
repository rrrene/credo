defmodule Credo.Code.Strings do
  @moduledoc """
  This module let's you strip strings from source code.
  """

  @sigil_delimiters [{"(", ")"}, {"[", "]"}, {"{", "}"}, {"<", ">"},
                      {"|", "|"}, {"\"", "\""}, {"'", "'"}]
  @all_string_sigils Enum.flat_map(@sigil_delimiters, fn({b, e}) ->
                        [{"~s#{b}", e}, {"~S#{b}", e}]
                      end)

  @doc """
  Replaces all characters inside string literals and string sigils
  with the equivalent amount of white-space.
  """
  def replace_with_spaces(source, replacement \\ " ") do
    parse_code(source, "", replacement)
  end

  defp parse_code("", acc, _replacement) do
    acc
  end
  for {sigil_start, sigil_end} <- @all_string_sigils do
    defp parse_code(<< unquote(sigil_start)::utf8, t::binary >>, acc, replacement) do
      parse_string_sigil(t, acc <> unquote(sigil_start), unquote(sigil_end), replacement)
    end
  end
  defp parse_code(<< "\\\""::utf8, t::binary >>, acc, replacement) do
    parse_code(t, acc <> "\\\"", replacement)
  end
  defp parse_code(<< "?\""::utf8, t::binary >>, acc, replacement) do
    parse_code(t, acc <> "?\"", replacement)
  end
  defp parse_code(<< "#"::utf8, t::binary >>, acc, replacement) do
    parse_comment(t, acc <> "#", replacement)
  end
  defp parse_code(<< "\"\"\""::utf8, t::binary >>, acc, replacement) do
    parse_heredoc(t, acc <> ~s("""), replacement)
  end
  defp parse_code(<< "\'\'\'"::utf8, t::binary >>, acc, replacement) do
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
  defp parse_string_literal(<< _::utf8, t::binary >>, acc, replacement) do
    parse_string_literal(t, acc <> replacement, replacement)
  end

  for {_sigil_start, sigil_end} <- @all_string_sigils do
    defp parse_string_sigil("", acc, unquote(sigil_end), _replacement) do
      acc
    end
    defp parse_string_sigil(<< "\\\\"::utf8, t::binary >>, acc, unquote(sigil_end), replacement) do
      parse_string_sigil(t, acc, unquote(sigil_end), replacement)
    end
    defp parse_string_sigil(<< "\\\""::utf8, t::binary >>, acc, unquote(sigil_end), replacement) do
      parse_string_sigil(t, acc, unquote(sigil_end), replacement)
    end
    defp parse_string_sigil(<< unquote(sigil_end)::utf8, t::binary >>, acc, unquote(sigil_end), replacement) do
      parse_code(t, acc <> unquote(sigil_end), replacement)
    end
    defp parse_string_sigil(<< "\n"::utf8, t::binary >>, acc, unquote(sigil_end), replacement) do
      parse_string_sigil(t, acc <> "\n", unquote(sigil_end), replacement)
    end
    defp parse_string_sigil(<< _::utf8, t::binary >>, acc, unquote(sigil_end), replacement) do
      parse_string_sigil(t, acc <> replacement, unquote(sigil_end), replacement)
    end
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
