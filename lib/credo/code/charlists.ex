defmodule Credo.Code.Charlists do
  @moduledoc """
  This module lets you strip charlists from source code.
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
    {"'", "'"}
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
  Replaces all characters inside charlists with the equivalent amount of
  white-space.
  """
  def replace_with_spaces(
        source_file,
        replacement \\ " ",
        interpolation_replacement \\ " ",
        filename \\ "nofilename"
      ) do
    {source, filename} = SourceFile.source_and_filename(source_file, filename)

    source
    |> InterpolationHelper.replace_interpolations(interpolation_replacement, filename)
    |> parse_code("", replacement)
  end

  defp parse_code("", acc, _replacement) do
    acc
  end

  for {sigil_start, sigil_end} <- removable_sigils do
    defp parse_code(<<unquote(sigil_start)::utf8, t::binary>>, acc, replacement) do
      parse_removable_sigil(
        t,
        acc <> unquote(sigil_start),
        unquote(sigil_end),
        replacement
      )
    end
  end

  for {sigil_start, sigil_end} <- all_heredocs_sigils do
    defp parse_code(<<unquote(sigil_start)::utf8, t::binary>>, acc, replacement) do
      parse_heredoc(
        t,
        acc <> unquote(sigil_start),
        replacement,
        unquote(sigil_end)
      )
    end
  end

  defp parse_code(<<"\"\"\""::utf8, t::binary>>, acc, replacement) do
    parse_heredoc(t, acc <> ~s("""), replacement, ~s("""))
  end

  defp parse_code(<<"\'\'\'"::utf8, t::binary>>, acc, replacement) do
    parse_heredoc(t, acc <> ~s('''), replacement, ~s('''))
  end

  for {sigil_start, sigil_end} <- all_string_sigils do
    defp parse_code(<<unquote(sigil_start)::utf8, t::binary>>, acc, replacement) do
      parse_string_sigil(
        t,
        acc <> unquote(sigil_start),
        unquote(sigil_end),
        replacement
      )
    end
  end

  defp parse_code(<<"\\\'"::utf8, t::binary>>, acc, replacement) do
    parse_code(t, acc <> "\\\'", replacement)
  end

  defp parse_code(<<"?'"::utf8, t::binary>>, acc, replacement) do
    parse_code(t, acc <> "?'", replacement)
  end

  defp parse_code(<<"?\""::utf8, t::binary>>, acc, replacement) do
    parse_code(t, acc <> "?\"", replacement)
  end

  defp parse_code(<<"'"::utf8, t::binary>>, acc, replacement) do
    parse_charlist(t, acc <> "'", replacement)
  end

  defp parse_code(<<"#"::utf8, t::binary>>, acc, replacement) do
    parse_comment(t, acc <> "#", replacement)
  end

  defp parse_code(<<"\""::utf8, t::binary>>, acc, replacement) do
    parse_string_literal(t, acc <> "\"", replacement)
  end

  defp parse_code(<<h::utf8, t::binary>>, acc, replacement) do
    parse_code(t, acc <> <<h::utf8>>, replacement)
  end

  defp parse_code(str, acc, replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)

    parse_code(t, acc <> h, replacement)
  end

  #
  # Comments
  #

  defp parse_comment("", acc, _replacement) do
    acc
  end

  defp parse_comment(<<"\n"::utf8, t::binary>>, acc, replacement) do
    parse_code(t, acc <> "\n", replacement)
  end

  defp parse_comment(str, acc, replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)

    parse_comment(t, acc <> h, replacement)
  end

  #
  # String Literals
  #

  defp parse_string_literal("", acc, _replacement) do
    acc
  end

  defp parse_string_literal(<<"\\\\"::utf8, t::binary>>, acc, replacement) do
    parse_string_literal(t, acc, replacement)
  end

  defp parse_string_literal(<<"\\\""::utf8, t::binary>>, acc, replacement) do
    parse_string_literal(t, acc, replacement)
  end

  defp parse_string_literal(<<"\""::utf8, t::binary>>, acc, replacement) do
    parse_code(t, acc <> ~s("), replacement)
  end

  defp parse_string_literal(<<"\n"::utf8, t::binary>>, acc, replacement) do
    parse_string_literal(t, acc <> "\n", replacement)
  end

  defp parse_string_literal(str, acc, replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)
    parse_string_literal(t, acc <> h, replacement)
  end

  #
  # Charlists
  #

  defp parse_charlist("", acc, _replacement) do
    acc
  end

  defp parse_charlist(<<"\\\\"::utf8, t::binary>>, acc, replacement) do
    parse_charlist(t, acc <> replacement <> replacement, replacement)
  end

  defp parse_charlist(<<"\\\'"::utf8, t::binary>>, acc, replacement) do
    parse_charlist(t, acc, replacement)
  end

  defp parse_charlist(<<"\'"::utf8, t::binary>>, acc, replacement) do
    parse_code(t, acc <> "'", replacement)
  end

  defp parse_charlist(<<"\n"::utf8, t::binary>>, acc, replacement) do
    parse_charlist(t, acc <> "\n", replacement)
  end

  defp parse_charlist(<<_::utf8, t::binary>>, acc, replacement) do
    parse_charlist(t, acc <> replacement, replacement)
  end

  #
  # Non-String Sigils
  #

  for sigil_end <- removable_sigil_ends do
    defp parse_removable_sigil("", acc, unquote(sigil_end), _replacement) do
      acc
    end

    defp parse_removable_sigil(
           <<"\\"::utf8, s::binary>>,
           acc,
           unquote(sigil_end),
           replacement
         ) do
      {h, t} = String.next_codepoint(s)

      parse_removable_sigil(t, acc <> "\\" <> h, unquote(sigil_end), replacement)
    end

    defp parse_removable_sigil(
           # \\
           <<"\\\\"::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement
         ) do
      parse_removable_sigil(t, acc <> "\\\\", unquote(sigil_end), replacement)
    end

    if sigil_end != "\"" do
      defp parse_removable_sigil(
             <<"\""::utf8, t::binary>>,
             acc,
             unquote(sigil_end),
             replacement
           ) do
        parse_removable_sigil(t, acc <> "\"", unquote(sigil_end), replacement)
      end
    end

    defp parse_removable_sigil(
           <<unquote("\\#{sigil_end}")::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement
         ) do
      parse_removable_sigil(
        t,
        acc <> unquote("\\#{sigil_end}"),
        unquote(sigil_end),
        replacement
      )
    end

    defp parse_removable_sigil(
           <<unquote(sigil_end)::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement
         ) do
      parse_code(t, acc <> unquote(sigil_end), replacement)
    end

    defp parse_removable_sigil(
           <<"\n"::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement
         ) do
      parse_removable_sigil(t, acc <> "\n", unquote(sigil_end), replacement)
    end

    defp parse_removable_sigil(
           str,
           acc,
           unquote(sigil_end),
           replacement
         )
         when is_binary(str) do
      {h, t} = String.next_codepoint(str)

      parse_removable_sigil(t, acc <> h, unquote(sigil_end), replacement)
    end
  end

  #
  # Sigils
  #

  for sigil_end <- all_string_sigil_ends do
    defp parse_string_sigil("", acc, unquote(sigil_end), _replacement) do
      acc
    end

    defp parse_string_sigil(
           <<"\\\\"::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement
         ) do
      parse_string_sigil(t, acc, unquote(sigil_end), replacement)
    end

    defp parse_string_sigil(
           <<"\\\""::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement
         ) do
      parse_string_sigil(t, acc, unquote(sigil_end), replacement)
    end

    defp parse_string_sigil(
           <<unquote(sigil_end)::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement
         ) do
      parse_code(t, acc <> unquote(sigil_end), replacement)
    end

    defp parse_string_sigil(
           <<"\n"::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement
         ) do
      parse_string_sigil(t, acc <> "\n", unquote(sigil_end), replacement)
    end

    defp parse_string_sigil(
           str,
           acc,
           unquote(sigil_end),
           replacement
         ) do
      {h, t} = String.next_codepoint(str)

      parse_string_sigil(t, acc <> h, unquote(sigil_end), replacement)
    end
  end

  #
  # Heredocs
  #

  defp parse_heredoc(<<"\"\"\""::utf8, t::binary>>, acc, replacement, "\"\"\"") do
    parse_code(t, acc <> ~s("""), replacement)
  end

  defp parse_heredoc(<<"\'\'\'"::utf8, t::binary>>, acc, replacement, "\'\'\'") do
    parse_code(t, acc <> ~s('''), replacement)
  end

  defp parse_heredoc("", acc, _replacement, _delimiter) do
    acc
  end

  defp parse_heredoc(<<"\\\\"::utf8, t::binary>>, acc, replacement, delimiter) do
    parse_heredoc(t, acc, replacement, delimiter)
  end

  defp parse_heredoc(<<"\\\""::utf8, t::binary>>, acc, replacement, delimiter) do
    parse_heredoc(t, acc, replacement, delimiter)
  end

  defp parse_heredoc(<<"\n"::utf8, t::binary>>, acc, replacement, delimiter) do
    parse_heredoc(t, acc <> "\n", replacement, delimiter)
  end

  defp parse_heredoc(str, acc, replacement, delimiter) do
    {h, t} = String.next_codepoint(str)

    parse_heredoc(t, acc <> h, replacement, delimiter)
  end
end
