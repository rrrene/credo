defmodule Credo.Code.Heredocs do
  @moduledoc """
  This module lets you strip heredocs from source code.
  """

  alias Credo.Code.InterpolationHelper
  alias Credo.SourceFile

  @doc """
  Replaces all characters inside heredocs
  with the equivalent amount of white-space.
  """
  def replace_with_spaces(
        source_file,
        replacement \\ " ",
        interpolation_replacement \\ " ",
        empty_line_replacement \\ "",
        filename \\ "nofilename"
      ) do
    {source, filename} = SourceFile.source_and_filename(source_file, filename)

    source
    |> InterpolationHelper.replace_interpolations(interpolation_replacement, filename)
    |> parse_code("", replacement, empty_line_replacement)
  end

  defp parse_code("", acc, _replacement, _empty_line_replacement) do
    acc
  end

  defp parse_code(<<"\"\"\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_heredoc(t, acc <> ~s("""), replacement, empty_line_replacement, ~s("""))
  end

  defp parse_code(<<"\'\'\'"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_heredoc(t, acc <> ~s('''), replacement, empty_line_replacement, ~s('''))
  end

  defp parse_code(<<"\\\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> "\\\"", replacement, empty_line_replacement)
  end

  defp parse_code(<<"#"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_comment(t, acc <> "#", replacement, empty_line_replacement)
  end

  defp parse_code(<<"?\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> "?\"", replacement, empty_line_replacement)
  end

  defp parse_code(<<"?'"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> "?\'", replacement, empty_line_replacement)
  end

  defp parse_code(<<"'"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_charlist(t, acc <> "'", replacement, empty_line_replacement)
  end

  defp parse_code(<<"\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_string_literal(t, acc <> "\"", replacement, empty_line_replacement)
  end

  defp parse_code(<<h::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> <<h::utf8>>, replacement, empty_line_replacement)
  end

  defp parse_code(str, acc, replacement, empty_line_replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)

    parse_code(t, acc <> h, replacement, empty_line_replacement)
  end

  #
  # Charlists
  #

  defp parse_charlist("", acc, _replacement, _empty_line_replacement) do
    acc
  end

  defp parse_charlist(<<"\\\\"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_charlist(t, acc <> "\\\\", replacement, empty_line_replacement)
  end

  defp parse_charlist(<<"\\\'"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_charlist(t, acc <> "\\\'", replacement, empty_line_replacement)
  end

  defp parse_charlist(<<"\'"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> "'", replacement, empty_line_replacement)
  end

  defp parse_charlist(<<"\n"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_charlist(t, acc <> "\n", replacement, empty_line_replacement)
  end

  defp parse_charlist(str, acc, replacement, empty_line_replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)

    parse_comment(t, acc <> h, replacement, empty_line_replacement)
  end

  #
  # Comments
  #

  defp parse_comment("", acc, _replacement, _empty_line_replacement) do
    acc
  end

  defp parse_comment(<<"\n"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> "\n", replacement, empty_line_replacement)
  end

  defp parse_comment(str, acc, replacement, empty_line_replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)

    parse_comment(t, acc <> h, replacement, empty_line_replacement)
  end

  #
  # Heredocs
  #

  defp parse_heredoc("", acc, _replacement, _empty_line_replacement, _here_doc_delimiter) do
    acc
  end

  defp parse_heredoc(
         <<"\\\\"::utf8, t::binary>>,
         acc,
         replacement,
         empty_line_replacement,
         here_doc_delimiter
       ) do
    parse_heredoc(t, acc, replacement, empty_line_replacement, here_doc_delimiter)
  end

  defp parse_heredoc(
         <<"\\\""::utf8, t::binary>>,
         acc,
         replacement,
         empty_line_replacement,
         here_doc_delimiter
       ) do
    parse_heredoc(t, acc, replacement, empty_line_replacement, here_doc_delimiter)
  end

  defp parse_heredoc(
         <<"\"\"\""::utf8, t::binary>>,
         acc,
         replacement,
         empty_line_replacement,
         "\"\"\""
       ) do
    acc = pad_replaced_heredoc(acc, ~s("""))

    parse_code(t, acc <> ~s("""), replacement, empty_line_replacement)
  end

  defp parse_heredoc(
         <<"\'\'\'"::utf8, t::binary>>,
         acc,
         replacement,
         empty_line_replacement,
         "\'\'\'"
       ) do
    acc = pad_replaced_heredoc(acc, ~s('''))

    parse_code(t, acc <> ~s('''), replacement, empty_line_replacement)
  end

  defp parse_heredoc(
         <<"\n"::utf8, t::binary>>,
         acc,
         replacement,
         empty_line_replacement,
         here_doc_delimiter
       ) do
    end_of_empty_line? = String.slice(acc, -1..-1) == "\n"

    acc =
      if end_of_empty_line? do
        acc <> empty_line_replacement
      else
        acc
      end

    parse_heredoc(t, acc <> "\n", replacement, empty_line_replacement, here_doc_delimiter)
  end

  defp parse_heredoc(
         <<_::utf8, t::binary>>,
         acc,
         replacement,
         empty_line_replacement,
         here_doc_delimiter
       ) do
    parse_heredoc(t, acc <> replacement, replacement, empty_line_replacement, here_doc_delimiter)
  end

  #
  # String Literals
  #

  defp parse_string_literal("", acc, _replacement, _empty_line_replacement) do
    acc
  end

  defp parse_string_literal(<<"\\\\"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_string_literal(t, acc <> "\\\\", replacement, empty_line_replacement)
  end

  defp parse_string_literal(<<"\\\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_string_literal(t, acc <> "\\\"", replacement, empty_line_replacement)
  end

  defp parse_string_literal(<<"\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> ~s("), replacement, empty_line_replacement)
  end

  defp parse_string_literal(<<"\n"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_string_literal(t, acc <> "\n", replacement, empty_line_replacement)
  end

  defp parse_string_literal(str, acc, replacement, empty_line_replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)

    parse_string_literal(t, acc <> h, replacement, empty_line_replacement)
  end

  defp pad_replaced_heredoc(acc, delimiter) do
    no_of_chars_to_replace =
      if acc =~ ~r/\n\Z/m do
        0
      else
        [leading_string] = Regex.run(~r/[^\n]*\Z/m, acc)

        String.length(leading_string)
      end

    pad_string = "\n" <> String.pad_leading("", no_of_chars_to_replace)

    {byte_index, _match_size} =
      Regex.scan(~r/#{delimiter}/m, acc, return: :index)
      |> List.last()
      |> List.first()

    length_after_byte_index = String.length(acc) - byte_index

    new_acc =
      acc
      |> String.slice(byte_index, length_after_byte_index)
      |> String.replace(~r/\n(.{#{no_of_chars_to_replace}})/, pad_string)

    String.slice(acc, 0, byte_index) <> new_acc
  end
end
