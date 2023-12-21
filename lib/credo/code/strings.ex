defmodule Credo.Code.Strings do
  @moduledoc """
  This module lets you strip strings from source code.
  """

  alias Credo.Code.InterpolationHelper
  alias Credo.SourceFile

  string_sigil_delimiters = [
    {"(", ")"},
    {"[", "]"},
    {"{", "}"},
    {"<", ">"},
    {"|", "|"},
    {"\"", "\""},
    {"'", "'"},
    {"/", "/"}
  ]

  heredocs_sigil_delimiters = [
    {"'''", "'''"},
    {~s("""), ~s(""")}
  ]

  all_string_sigils =
    Enum.flat_map(string_sigil_delimiters, fn {b, e} ->
      [{"~s#{b}", e}, {"~S#{b}", e}]
    end)

  all_string_sigil_ends = Enum.map(string_sigil_delimiters, &elem(&1, 1))

  all_heredocs_sigils =
    Enum.flat_map(heredocs_sigil_delimiters, fn {b, e} ->
      [{"~s#{b}", e}, {"~S#{b}", e}]
    end)

  alphabet = ~w(a b c d e f g h i j k l m n o p q r t u v w x y z)

  sigil_delimiters = [
    {"(", ")"},
    {"[", "]"},
    {"{", "}"},
    {"<", ">"},
    {"|", "|"},
    {"/", "/"},
    {"\"\"\"", "\"\"\""},
    {"\"", "\""},
    {"'", "'"}
  ]

  all_sigil_chars =
    Enum.flat_map(alphabet, fn a ->
      [a, String.upcase(a)]
    end)

  all_sigil_starts = Enum.map(all_sigil_chars, fn c -> "~#{c}" end)

  removable_sigil_ends = Enum.map(sigil_delimiters, &elem(&1, 1))

  removable_sigils =
    sigil_delimiters
    |> Enum.flat_map(fn {b, e} ->
      Enum.flat_map(all_sigil_starts, fn start ->
        [{"#{start}#{b}", e}, {"#{start}#{b}", e}]
      end)
    end)
    |> Enum.uniq()

  @doc """
  Replaces all characters inside string literals and string sigils
  with the equivalent amount of white-space.
  """
  def replace_with_spaces(
        source_file,
        replacement \\ " ",
        interpolation_replacement \\ " ",
        filename \\ "nofilename",
        empty_line_replacement \\ ""
      ) do
    {source, filename} = SourceFile.source_and_filename(source_file, filename)

    source
    |> InterpolationHelper.replace_interpolations(interpolation_replacement, filename)
    |> parse_code("", replacement, empty_line_replacement)
  end

  defp parse_code("", acc, _replacement, _empty_line_replacement) do
    acc
  end

  for {sigil_start, sigil_end} <- removable_sigils do
    defp parse_code(
           <<unquote(sigil_start)::utf8, t::binary>>,
           acc,
           replacement,
           empty_line_replacement
         ) do
      parse_removable_sigil(
        t,
        acc <> unquote(sigil_start),
        unquote(sigil_end),
        replacement,
        empty_line_replacement
      )
    end
  end

  for {sigil_start, sigil_end} <- all_heredocs_sigils do
    defp parse_code(
           <<unquote(sigil_start)::utf8, t::binary>>,
           acc,
           replacement,
           empty_line_replacement
         ) do
      parse_heredoc(
        t,
        acc <> unquote(sigil_start),
        "",
        replacement,
        unquote(sigil_end),
        empty_line_replacement
      )
    end
  end

  defp parse_code(<<"\"\"\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_heredoc(t, acc <> ~s("""), "", replacement, ~s("""), empty_line_replacement)
  end

  defp parse_code(<<"\'\'\'"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_heredoc(t, acc <> ~s('''), "", replacement, ~s('''), empty_line_replacement)
  end

  for {sigil_start, sigil_end} <- all_string_sigils do
    defp parse_code(
           <<unquote(sigil_start)::utf8, t::binary>>,
           acc,
           replacement,
           empty_line_replacement
         ) do
      parse_string_sigil(
        t,
        acc <> unquote(sigil_start),
        unquote(sigil_end),
        replacement,
        empty_line_replacement
      )
    end
  end

  defp parse_code(<<"\\\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> "\\\"", replacement, empty_line_replacement)
  end

  defp parse_code(<<"\\\'"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> "\\\'", replacement, empty_line_replacement)
  end

  defp parse_code(<<"?'"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> "?'", replacement, empty_line_replacement)
  end

  defp parse_code(<<"'"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_charlist(t, acc <> "'", replacement, empty_line_replacement)
  end

  defp parse_code(<<"?\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> "?\"", replacement, empty_line_replacement)
  end

  defp parse_code(<<"#"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_comment(t, acc <> "#", replacement, empty_line_replacement)
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

    parse_charlist(t, acc <> h, replacement, empty_line_replacement)
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
  # String Literals
  #

  defp parse_string_literal("", acc, _replacement, _empty_line_replacement) do
    acc
  end

  defp parse_string_literal(<<"\\\\"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_string_literal(t, acc, replacement, empty_line_replacement)
  end

  defp parse_string_literal(<<"\\\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_string_literal(t, acc, replacement, empty_line_replacement)
  end

  defp parse_string_literal(<<"\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, acc <> ~s("), replacement, empty_line_replacement)
  end

  defp parse_string_literal(<<"\n"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    acc =
      if String.last(acc) == "\n" do
        acc <> empty_line_replacement
      else
        acc
      end

    parse_string_literal(t, acc <> "\n", replacement, empty_line_replacement)
  end

  defp parse_string_literal(<<_::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_string_literal(t, acc <> replacement, replacement, empty_line_replacement)
  end

  #
  # Non-String Sigils
  #

  for sigil_end <- removable_sigil_ends do
    defp parse_removable_sigil("", acc, unquote(sigil_end), _replacement, _empty_line_replacement) do
      acc
    end

    defp parse_removable_sigil(
           <<"\\"::utf8, s::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement
         ) do
      {h, t} = String.next_codepoint(s)

      parse_removable_sigil(
        t,
        acc <> "\\" <> h,
        unquote(sigil_end),
        replacement,
        empty_line_replacement
      )
    end

    defp parse_removable_sigil(
           # \\
           <<"\\\\"::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement
         ) do
      parse_removable_sigil(
        t,
        acc <> "\\\\",
        unquote(sigil_end),
        replacement,
        empty_line_replacement
      )
    end

    defp parse_removable_sigil(
           <<unquote(sigil_end)::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement
         ) do
      parse_code(t, acc <> unquote(sigil_end), replacement, empty_line_replacement)
    end

    defp parse_removable_sigil(
           <<unquote("\\#{sigil_end}")::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement
         ) do
      parse_removable_sigil(
        t,
        acc <> unquote("\\#{sigil_end}"),
        unquote(sigil_end),
        replacement,
        empty_line_replacement
      )
    end

    if sigil_end != "\"" do
      defp parse_removable_sigil(
             <<"\""::utf8, t::binary>>,
             acc,
             unquote(sigil_end),
             replacement,
             empty_line_replacement
           ) do
        parse_removable_sigil(
          t,
          acc <> "\"",
          unquote(sigil_end),
          replacement,
          empty_line_replacement
        )
      end
    end

    defp parse_removable_sigil(
           <<"\n"::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement
         ) do
      parse_removable_sigil(
        t,
        acc <> "\n",
        unquote(sigil_end),
        replacement,
        empty_line_replacement
      )
    end

    defp parse_removable_sigil(
           str,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement
         )
         when is_binary(str) do
      {h, t} = String.next_codepoint(str)

      parse_removable_sigil(t, acc <> h, unquote(sigil_end), replacement, empty_line_replacement)
    end
  end

  #
  # Sigils
  #

  for sigil_end <- all_string_sigil_ends do
    defp parse_string_sigil("", acc, unquote(sigil_end), _replacement, _empty_line_replacement) do
      acc
    end

    defp parse_string_sigil(
           <<"\\\\"::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement
         ) do
      parse_string_sigil(
        t,
        acc <> replacement <> replacement,
        unquote(sigil_end),
        replacement,
        empty_line_replacement
      )
    end

    defp parse_string_sigil(
           <<"\\\""::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement
         ) do
      parse_string_sigil(
        t,
        acc <> replacement <> replacement,
        unquote(sigil_end),
        replacement,
        empty_line_replacement
      )
    end

    defp parse_string_sigil(
           <<unquote(sigil_end)::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement
         ) do
      parse_code(t, acc <> unquote(sigil_end), replacement, empty_line_replacement)
    end

    defp parse_string_sigil(
           <<"\n"::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement
         ) do
      acc =
        if String.last(acc) == "\n" do
          acc <> empty_line_replacement
        else
          acc
        end

      parse_string_sigil(t, acc <> "\n", unquote(sigil_end), replacement, empty_line_replacement)
    end

    defp parse_string_sigil(
           <<_::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement
         ) do
      parse_string_sigil(
        t,
        acc <> replacement,
        unquote(sigil_end),
        replacement,
        empty_line_replacement
      )
    end
  end

  #
  # Heredocs
  #

  defp parse_heredoc(
         <<"\"\"\""::utf8, t::binary>>,
         acc,
         heredoc_acc,
         "" = replacement,
         "\"\"\"",
         empty_line_replacement
       ) do
    parse_code(t, acc <> heredoc_acc <> "\"\"\"", replacement, empty_line_replacement)
  end

  defp parse_heredoc(
         <<"\"\"\""::utf8, t::binary>>,
         acc,
         heredoc_acc,
         " " = replacement,
         "\"\"\"",
         empty_line_replacement
       ) do
    parse_code(t, acc <> heredoc_acc <> "\"\"\"", replacement, empty_line_replacement)
  end

  defp parse_heredoc(
         <<"\"\"\""::utf8, t::binary>>,
         acc,
         heredoc_acc,
         replacement,
         "\"\"\"",
         empty_line_replacement
       ) do
    heredoc_acc = heredoc_acc <> "\"\"\""

    heredoc_acc =
      case Regex.run(~r/\n([#{replacement}]+)\"\"\"\z/m, heredoc_acc) do
        [_, indent_string] ->
          x = String.length(indent_string)
          Regex.replace(~r/^(.{#{x}})/m, heredoc_acc, String.pad_trailing("", x))

        _ ->
          heredoc_acc
      end

    parse_code(t, acc <> heredoc_acc, replacement, empty_line_replacement)
  end

  defp parse_heredoc(
         <<"\'\'\'"::utf8, t::binary>>,
         acc,
         heredoc_acc,
         "" = replacement,
         "\'\'\'",
         empty_line_replacement
       ) do
    parse_code(t, acc <> heredoc_acc <> "\'\'\'", replacement, empty_line_replacement)
  end

  defp parse_heredoc(
         <<"\'\'\'"::utf8, t::binary>>,
         acc,
         heredoc_acc,
         " " = replacement,
         "\'\'\'",
         empty_line_replacement
       ) do
    parse_code(t, acc <> heredoc_acc <> "\'\'\'", replacement, empty_line_replacement)
  end

  defp parse_heredoc(
         <<"\'\'\'"::utf8, t::binary>>,
         acc,
         heredoc_acc,
         replacement,
         "\'\'\'",
         empty_line_replacement
       ) do
    heredoc_acc = heredoc_acc <> "\'\'\'"

    heredoc_acc =
      case Regex.run(~r/\n([#{replacement}]+)\'\'\'\z/m, heredoc_acc) do
        [_, indent_string] ->
          x = String.length(indent_string)
          Regex.replace(~r/^(.{#{x}})/m, heredoc_acc, String.pad_trailing("", x))

        _ ->
          heredoc_acc
      end

    parse_code(t, acc <> heredoc_acc, replacement, empty_line_replacement)
  end

  defp parse_heredoc("", acc, _heredoc_acc, _replacement, _delimiter, _empty_line_replacement) do
    acc
  end

  defp parse_heredoc(
         <<"\\\\"::utf8, t::binary>>,
         acc,
         heredoc_acc,
         replacement,
         delimiter,
         empty_line_replacement
       ) do
    parse_heredoc(t, acc, heredoc_acc, replacement, delimiter, empty_line_replacement)
  end

  defp parse_heredoc(
         <<"\\\""::utf8, t::binary>>,
         acc,
         heredoc_acc,
         replacement,
         delimiter,
         empty_line_replacement
       ) do
    parse_heredoc(t, acc, heredoc_acc, replacement, delimiter, empty_line_replacement)
  end

  defp parse_heredoc(
         <<"\n"::utf8, t::binary>>,
         acc,
         heredoc_acc,
         replacement,
         delimiter,
         empty_line_replacement
       ) do
    parse_heredoc(t, acc, heredoc_acc <> "\n", replacement, delimiter, empty_line_replacement)
  end

  defp parse_heredoc(
         <<_::utf8, t::binary>>,
         acc,
         heredoc_acc,
         replacement,
         delimiter,
         empty_line_replacement
       ) do
    parse_heredoc(
      t,
      acc,
      heredoc_acc <> replacement,
      replacement,
      delimiter,
      empty_line_replacement
    )
  end
end
