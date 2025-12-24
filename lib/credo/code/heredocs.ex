defmodule Credo.Code.Heredocs do
  @moduledoc """
  This module lets you strip heredocs from source code.
  """

  alias Credo.Code.InterpolationHelper
  alias Credo.SourceFile

  alphabet = ~w(a b c d e f g h i j k l m n o p q r s t u v w x y z)

  sigil_delimiters = [
    {"(", ")"},
    {"[", "]"},
    {"{", "}"},
    {"<", ">"},
    {"|", "|"},
    {"/", "/"},
    {"\"", "\""},
    {"'", "'"}
  ]

  all_sigil_chars =
    Enum.flat_map(alphabet, fn a ->
      [a, String.upcase(a)]
    end)

  all_sigil_starts = Enum.map(all_sigil_chars, fn c -> "~#{c}" end)

  non_removable_normal_sigils =
    sigil_delimiters
    |> Enum.flat_map(fn {b, e} ->
      Enum.flat_map(all_sigil_starts, fn start ->
        [{"#{start}#{b}", e}, {"#{start}#{b}", e}]
      end)
    end)
    |> Enum.uniq()

  non_removable_normal_sigil_ends = Enum.map(sigil_delimiters, &elem(&1, 1))

  removable_heredoc_sigil_delimiters = [
    {"\"\"\"", "\"\"\""},
    {"'''", "'''"}
  ]

  removable_heredoc_sigils =
    removable_heredoc_sigil_delimiters
    |> Enum.flat_map(fn {b, e} ->
      Enum.flat_map(all_sigil_starts, fn start ->
        [{"#{start}#{b}", e}, {"#{start}#{b}", e}]
      end)
    end)
    |> Enum.uniq()

  removable_heredoc_sigil_ends = Enum.map(removable_heredoc_sigil_delimiters, &elem(&1, 1))

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
    |> parse_code([], replacement, empty_line_replacement)
    |> Enum.reverse()
    |> IO.iodata_to_binary()
  end

  defp parse_code("", acc, _replacement, _empty_line_replacement) do
    acc
  end

  for {sigil_start, sigil_end} <- removable_heredoc_sigils do
    defp parse_code(
           <<unquote(sigil_start)::utf8, t::binary>>,
           acc,
           replacement,
           empty_line_replacement
         ) do
      parse_removable_heredoc_sigil(
        t,
        [unquote(sigil_start) | acc],
        unquote(sigil_end),
        replacement,
        empty_line_replacement,
        []
      )
    end
  end

  for {sigil_start, sigil_end} <- non_removable_normal_sigils do
    defp parse_code(
           <<unquote(sigil_start)::utf8, t::binary>>,
           acc,
           replacement,
           empty_line_replacement
         ) do
      parse_non_removable_normal_sigil(
        t,
        [unquote(sigil_start) | acc],
        unquote(sigil_end),
        replacement,
        empty_line_replacement
      )
    end
  end

  defp parse_code(<<"\"\"\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_heredoc(
      t,
      [~s(""") | acc],
      replacement,
      empty_line_replacement,
      ~s("""),
      []
    )
  end

  defp parse_code(<<"\'\'\'"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_heredoc(
      t,
      [~s(''') | acc],
      replacement,
      empty_line_replacement,
      ~s('''),
      []
    )
  end

  defp parse_code(<<"\\\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, ["\\\"" | acc], replacement, empty_line_replacement)
  end

  defp parse_code(<<"#"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_comment(t, ["#" | acc], replacement, empty_line_replacement)
  end

  defp parse_code(<<"?\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, ["?\"" | acc], replacement, empty_line_replacement)
  end

  defp parse_code(<<"?'"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, ["?\'" | acc], replacement, empty_line_replacement)
  end

  defp parse_code(<<"'"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_charlist(t, ["'" | acc], replacement, empty_line_replacement)
  end

  defp parse_code(<<"\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_string_literal(t, ["\"" | acc], replacement, empty_line_replacement)
  end

  defp parse_code(<<h::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, [<<h::utf8>> | acc], replacement, empty_line_replacement)
  end

  defp parse_code(str, acc, replacement, empty_line_replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)

    parse_code(t, [h | acc], replacement, empty_line_replacement)
  end

  #
  # Charlists
  #

  defp parse_charlist("", acc, _replacement, _empty_line_replacement) do
    acc
  end

  defp parse_charlist(<<"\\\\"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_charlist(t, ["\\\\" | acc], replacement, empty_line_replacement)
  end

  defp parse_charlist(<<"\\\'"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_charlist(t, ["\\\'" | acc], replacement, empty_line_replacement)
  end

  defp parse_charlist(<<"\'"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, ["'" | acc], replacement, empty_line_replacement)
  end

  defp parse_charlist(<<"\n"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_charlist(t, ["\n" | acc], replacement, empty_line_replacement)
  end

  defp parse_charlist(<<h::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_charlist(t, [<<h::utf8>> | acc], replacement, empty_line_replacement)
  end

  defp parse_charlist(str, acc, replacement, empty_line_replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)

    parse_comment(t, [h | acc], replacement, empty_line_replacement)
  end

  #
  # Comments
  #

  defp parse_comment("", acc, _replacement, _empty_line_replacement) do
    acc
  end

  defp parse_comment(<<"\n"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, ["\n" | acc], replacement, empty_line_replacement)
  end

  defp parse_comment(<<h::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_comment(t, [<<h::utf8>> | acc], replacement, empty_line_replacement)
  end

  defp parse_comment(str, acc, replacement, empty_line_replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)

    parse_comment(t, [h | acc], replacement, empty_line_replacement)
  end

  #
  # "Normal" Sigils (e.g. `~S"..."` or `~s(...)`)
  #

  for sigil_end <- non_removable_normal_sigil_ends do
    defp parse_non_removable_normal_sigil(
           "",
           acc,
           unquote(sigil_end),
           _replacement,
           _empty_line_replacement
         ) do
      acc
    end

    defp parse_non_removable_normal_sigil(
           <<"\\\\"::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement
         ) do
      parse_non_removable_normal_sigil(
        t,
        acc,
        unquote(sigil_end),
        replacement,
        empty_line_replacement
      )
    end

    defp parse_non_removable_normal_sigil(
           <<unquote("\\#{sigil_end}")::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement
         ) do
      parse_non_removable_normal_sigil(
        t,
        [replacement, replacement | acc],
        unquote(sigil_end),
        replacement,
        empty_line_replacement
      )
    end

    defp parse_non_removable_normal_sigil(
           <<unquote(sigil_end)::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement
         ) do
      parse_code(t, [unquote(sigil_end) | acc], replacement, empty_line_replacement)
    end

    defp parse_non_removable_normal_sigil(
           <<"\n"::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement
         ) do
      parse_non_removable_normal_sigil(
        t,
        ["\n" | acc],
        unquote(sigil_end),
        replacement,
        empty_line_replacement
      )
    end

    defp parse_non_removable_normal_sigil(
           str,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement
         ) do
      {h, t} = String.next_codepoint(str)

      parse_non_removable_normal_sigil(
        t,
        [h | acc],
        unquote(sigil_end),
        replacement,
        empty_line_replacement
      )
    end
  end

  #
  # Removable Sigils (e.g. `~S"""`)
  #

  for sigil_end <- removable_heredoc_sigil_ends do
    defp parse_removable_heredoc_sigil(
           "",
           acc,
           unquote(sigil_end),
           _replacement,
           _empty_line_replacement,
           _current_line
         ) do
      acc
    end

    defp parse_removable_heredoc_sigil(
           <<"\\\\"::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement,
           current_line
         ) do
      parse_removable_heredoc_sigil(
        t,
        [replacement, replacement | acc],
        unquote(sigil_end),
        replacement,
        empty_line_replacement,
        current_line
      )
    end

    defp parse_removable_heredoc_sigil(
           <<unquote("\\#{sigil_end}")::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement,
           current_line
         ) do
      parse_removable_heredoc_sigil(
        t,
        [replacement, replacement | acc],
        unquote(sigil_end),
        replacement,
        empty_line_replacement,
        [replacement, replacement | current_line]
      )
    end

    defp parse_removable_heredoc_sigil(
           <<unquote(sigil_end)::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement,
           _current_line
         ) do
      parse_code(t, [unquote(sigil_end) | acc], replacement, empty_line_replacement)
    end

    defp parse_removable_heredoc_sigil(
           <<"\n"::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement,
           current_line
         ) do
      acc =
        if current_line == ["\n"] do
          [empty_line_replacement | acc]
        else
          acc
        end

      parse_removable_heredoc_sigil(
        t,
        ["\n" | acc],
        unquote(sigil_end),
        replacement,
        empty_line_replacement,
        ["\n"]
      )
    end

    defp parse_removable_heredoc_sigil(
           <<indentation::binary-size(1), t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement,
           current_line
         )
         when indentation in [" ", "\t"] and current_line in [[], ["\n"]] do
      parse_removable_heredoc_sigil(
        t,
        [indentation | acc],
        unquote(sigil_end),
        replacement,
        empty_line_replacement,
        current_line
      )
    end

    defp parse_removable_heredoc_sigil(
           <<_::utf8, t::binary>>,
           acc,
           unquote(sigil_end),
           replacement,
           empty_line_replacement,
           current_line
         ) do
      parse_removable_heredoc_sigil(
        t,
        [replacement | acc],
        unquote(sigil_end),
        replacement,
        empty_line_replacement,
        [replacement | current_line]
      )
    end
  end

  #
  # Heredocs
  #

  defp parse_heredoc(
         "",
         acc,
         _replacement,
         _empty_line_replacement,
         _here_doc_delimiter,
         _current_line
       ) do
    acc
  end

  defp parse_heredoc(
         <<"\\\\"::utf8, t::binary>>,
         acc,
         replacement,
         empty_line_replacement,
         here_doc_delimiter,
         current_line
       ) do
    parse_heredoc(
      t,
      acc,
      replacement,
      empty_line_replacement,
      here_doc_delimiter,
      current_line
    )
  end

  defp parse_heredoc(
         <<"\\\""::utf8, t::binary>>,
         acc,
         replacement,
         empty_line_replacement,
         here_doc_delimiter,
         current_line
       ) do
    parse_heredoc(
      t,
      acc,
      replacement,
      empty_line_replacement,
      here_doc_delimiter,
      current_line
    )
  end

  defp parse_heredoc(
         <<"\"\"\""::utf8, t::binary>>,
         acc,
         replacement,
         empty_line_replacement,
         "\"\"\"",
         _current_line
       ) do
    parse_code(t, [~s(""") | acc], replacement, empty_line_replacement)
  end

  defp parse_heredoc(
         <<"\'\'\'"::utf8, t::binary>>,
         acc,
         replacement,
         empty_line_replacement,
         "\'\'\'",
         _
       ) do
    parse_code(t, [~s(''') | acc], replacement, empty_line_replacement)
  end

  defp parse_heredoc(
         <<"\n"::utf8, t::binary>>,
         acc,
         replacement,
         empty_line_replacement,
         here_doc_delimiter,
         current_line
       ) do
    acc =
      if current_line == ["\n"] do
        [empty_line_replacement | acc]
      else
        acc
      end

    parse_heredoc(
      t,
      ["\n" | acc],
      replacement,
      empty_line_replacement,
      here_doc_delimiter,
      ["\n"]
    )
  end

  defp parse_heredoc(
         <<indentation::binary-size(1), t::binary>>,
         acc,
         replacement,
         empty_line_replacement,
         here_doc_delimiter,
         current_line
       )
       when indentation in [" ", "\t"] and current_line in [[], ["\n"]] do
    parse_heredoc(
      t,
      [indentation | acc],
      replacement,
      empty_line_replacement,
      here_doc_delimiter,
      current_line
    )
  end

  defp parse_heredoc(
         <<_::utf8, t::binary>>,
         acc,
         replacement,
         empty_line_replacement,
         here_doc_delimiter,
         current_line
       ) do
    parse_heredoc(
      t,
      [replacement | acc],
      replacement,
      empty_line_replacement,
      here_doc_delimiter,
      [replacement | current_line]
    )
  end

  #
  # String Literals
  #

  defp parse_string_literal("", acc, _replacement, _empty_line_replacement) do
    acc
  end

  defp parse_string_literal(<<"\\\\"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_string_literal(t, ["\\\\" | acc], replacement, empty_line_replacement)
  end

  defp parse_string_literal(<<"\\\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_string_literal(t, ["\\\"" | acc], replacement, empty_line_replacement)
  end

  defp parse_string_literal(<<"\""::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_code(t, [~s(") | acc], replacement, empty_line_replacement)
  end

  defp parse_string_literal(<<"\n"::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_string_literal(t, ["\n" | acc], replacement, empty_line_replacement)
  end

  defp parse_string_literal(<<h::utf8, t::binary>>, acc, replacement, empty_line_replacement) do
    parse_string_literal(t, [<<h::utf8>> | acc], replacement, empty_line_replacement)
  end

  defp parse_string_literal(str, acc, replacement, empty_line_replacement) when is_binary(str) do
    {h, t} = String.next_codepoint(str)

    parse_string_literal(t, [h | acc], replacement, empty_line_replacement)
  end
end
