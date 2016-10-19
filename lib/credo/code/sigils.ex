defmodule Credo.Code.Sigils do
  @moduledoc """
  This module let's you strip sigils from source code.
  """

  @sigil_delimiters [{"(", ")"}, {"[", "]"}, {"{", "}"}, {"<", ">"},
                      {"|", "|"}, {"/", "/"}, {"\"\"\"", "\"\"\""}, {"\"", "\""}, {"'", "'"}]
  @all_sigil_chars  ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)
                    |> Enum.flat_map(fn a -> [a, a |> String.upcase] end)
  @all_sigil_starts @all_sigil_chars |> Enum.map(fn c -> "~#{c}" end)
  @removable_sigils @sigil_delimiters
                    |> Enum.flat_map(fn({b, e}) ->
                        Enum.flat_map(@all_sigil_starts, fn(start) ->
                          [{"#{start}#{b}", e}, {"#{start}#{b}", e}]
                        end)
                      end)

  @doc """
  Replaces all characters inside all sigils with the equivalent amount of
  white-space.
  """
  def replace_with_spaces(source, replacement \\ " ") do
    parse_code(source, "", replacement)
  end

  defp parse_code("", acc, _replacement) do
    acc
  end
  for {sigil_start, sigil_end} <- @removable_sigils do
    defp parse_code(<< unquote(sigil_start)::utf8, t::binary >>, acc, replacement) do
      parse_removable_sigil(t, acc <> unquote(sigil_start), unquote(sigil_end), replacement)
    end
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
  defp parse_code(<< "\""::utf8, t::binary >>, acc, replacement) do
    parse_string_literal(t, acc <> "\"", replacement)
  end
  defp parse_code(<< h::utf8, t::binary >>, acc, replacement) do
    parse_code(t, acc <> <<h :: utf8>>, replacement)
  end
  defp parse_code(str, acc, replacement) when is_binary(str) do
    {h, t} = str |> String.next_codepoint
    parse_code(t, acc <> h, replacement)
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
    {h, t} = str |> String.next_codepoint
    parse_string_literal(t, acc <> h, replacement)
  end

  for {_sigil_start, sigil_end} <- @removable_sigils do
    defp parse_removable_sigil("", acc, unquote(sigil_end), _replacement) do
      acc
    end
    defp parse_removable_sigil(<< "\\\\"::utf8, t::binary >>, acc, unquote(sigil_end), replacement) do
      parse_removable_sigil(t, acc, unquote(sigil_end), replacement)
    end
    defp parse_removable_sigil(<< "\\\""::utf8, t::binary >>, acc, unquote(sigil_end), replacement) do
      parse_removable_sigil(t, acc, unquote(sigil_end), replacement)
    end
    defp parse_removable_sigil(<< unquote(sigil_end)::utf8, t::binary >>, acc, unquote(sigil_end), replacement) do
      parse_code(t, acc <> unquote(sigil_end), replacement)
    end
    defp parse_removable_sigil(<< "\n"::utf8, t::binary >>, acc, unquote(sigil_end), replacement) do
      parse_removable_sigil(t, acc <> "\n", unquote(sigil_end), replacement)
    end
    defp parse_removable_sigil(<< _::utf8, t::binary >>, acc, unquote(sigil_end), replacement) do
      parse_removable_sigil(t, acc <> replacement, unquote(sigil_end), replacement)
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
  defp parse_heredoc(str, acc, replacement) when is_binary(str) do
    {h, t} = str |> String.next_codepoint
    parse_heredoc(t, acc <> h, replacement)
  end
end
