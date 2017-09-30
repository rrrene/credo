defmodule Credo.Check.Readability.MaxLineLength do
  @moduledoc """
  Checks for the length of lines.

  Ignores function definitions and (multi-)line strings by default.
  """

  @explanation [
    check: @moduledoc,
    params: [
      max_length: "The maximum number of characters a line may consist of.",
      ignore_definitions: "Set to `true` to ignore lines including function definitions.",
      ignore_specs: "Set to `true` to ignore lines including `@spec`s.",
      ignore_strings: "Set to `true` to ignore lines that are strings or in heredocs",
    ]
  ]
  @default_params [
    max_length: 80,
    ignore_definitions: true,
    ignore_specs: false,
    ignore_strings: true
  ]

  @def_ops [:def, :defp, :defmacro]

  use Credo.Check, base_priority: :low

  @sigil_delimiters [{"(", ")"}, {"[", "]"}, {"{", "}"}, {"<", ">"},
                      {"|", "|"}, {"\"", "\""}, {"'", "'"}]
  @all_string_sigils Enum.flat_map(@sigil_delimiters, fn({b, e}) ->
                        [{"~s#{b}", e}, {"~S#{b}", e}]
                      end)

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    max_length = Params.get(params, :max_length, @default_params)
    ignore_definitions = Params.get(params, :ignore_definitions, @default_params)
    ignore_specs = Params.get(params, :ignore_specs, @default_params)
    ignore_strings = Params.get(params, :ignore_strings, @default_params)

    definitions = Credo.Code.prewalk(source_file, &find_definitions/2)
    specs = Credo.Code.prewalk(source_file, &find_specs/2)

    source = SourceFile.source(source_file)
    source =
      if ignore_strings do
        replace_with_spaces(source, "")
      else
        source
      end

    lines = Credo.Code.to_lines(source)

    Enum.reduce(lines, [], fn({line_no, line}, issues) ->
      if String.length(line) > max_length do
        if refute_issue?(line_no, definitions, ignore_definitions, specs, ignore_specs) do
          issues
        else
          [issue_for(line_no, max_length, line, issue_meta) | issues]
        end
      else
        issues
      end
    end)
  end

  for op <- @def_ops do
    defp find_definitions({unquote(op), meta, arguments} = ast, definitions) when is_list(arguments) do
      {ast, [meta[:line] | definitions]}
    end
  end
  defp find_definitions(ast, definitions) do
    {ast, definitions}
  end

  defp find_specs({:spec, meta, arguments} = ast, specs) when is_list(arguments) do
    {ast, [meta[:line] | specs]}
  end
  defp find_specs(ast, specs) do
    {ast, specs}
  end

  defp refute_issue?(line_no, definitions, ignore_definitions, specs, ignore_specs) do
    ignore_definitions? =
      if ignore_definitions do
        Enum.member?(definitions, line_no)
      else
        false
      end

    ignore_specs? =
      if ignore_specs do
        Enum.member?(specs, line_no)
      else
        false
      end

    ignore_definitions? || ignore_specs?
  end

  defp issue_for(line_no, max_length, line, issue_meta) do
    line_length = String.length(line)
    column = max_length + 1
    trigger = String.slice(line, max_length, line_length - max_length)

    format_issue issue_meta,
      message: "Line is too long (max is #{max_length}, was #{line_length}).",
      line_no: line_no,
      column: column,
      trigger: trigger
  end

  def replace_with_spaces(source, replacement \\ " ") do
    parse_code(source, "", replacement, false)
  end

  defp parse_code("", acc, _replacement, _sol) do
    acc
  end
  for {sigil_start, sigil_end} <- @all_string_sigils do
    defp parse_code(<< unquote(sigil_start)::utf8, t::binary >>, acc, replacement, sol) do
      parse_string_sigil(t, acc <> unquote(sigil_start), unquote(sigil_end), replacement, sol)
    end
  end
  defp parse_code(<< "\\\""::utf8, t::binary >>, acc, replacement, sol) do
    parse_code(t, acc <> "\\\"", replacement, false)
  end
  defp parse_code(<< "?\""::utf8, t::binary >>, acc, replacement, sol) do
    parse_code(t, acc <> "?\"", replacement, false)
  end
  defp parse_code(<< "#"::utf8, t::binary >>, acc, replacement, sol) do
    parse_comment(t, acc <> "#", replacement, false)
  end
  defp parse_code(<< "\"\"\""::utf8, t::binary >>, acc, replacement, sol) do
    parse_heredoc(t, acc <> ~s("""), replacement, sol)
  end
  defp parse_code(<< "\'\'\'"::utf8, t::binary >>, acc, replacement, sol) do
    parse_heredoc(t, acc <> ~s("""), replacement, sol)
  end
  defp parse_code(<< "\""::utf8, t::binary >>, acc, replacement, sol) do
    parse_string_literal(t, acc <> "\"", replacement, sol)
  end
  defp parse_code(<< "\n"::utf8, t::binary >>, acc, replacement, sol) do
    parse_code(t, acc <> "\n", replacement, true)
  end
  defp parse_code(<< " "::utf8, t::binary >>, acc, replacement, sol) do
    parse_code(t, acc <> " ", replacement, sol)
  end
  defp parse_code(<< h::utf8, t::binary >>, acc, replacement, sol) do
    parse_code(t, acc <> <<h :: utf8>>, replacement, false)
  end
  defp parse_code(str, acc, replacement, sol) when is_binary(str) do
    {h, t} = String.next_codepoint(str)

    parse_code(t, acc <> h, replacement, sol)
  end

  defp parse_comment("", acc, _replacement, sol) do
    acc
  end
  defp parse_comment(<< "\n"::utf8, t::binary >>, acc, replacement, sol) do
    parse_code(t, acc <> "\n", replacement, true)
  end
  defp parse_comment(str, acc, replacement, sol) when is_binary(str) do
    {h, t} = String.next_codepoint(str)

    parse_comment(t, acc <> h, replacement, sol)
  end

  defp parse_string_literal("", acc, _replacement, sol) do
    acc
  end
  defp parse_string_literal(<< "\\\\"::utf8, t::binary >>, acc, replacement, sol) do
    parse_string_literal(t, acc, replacement, sol)
  end
  defp parse_string_literal(<< "\\\""::utf8, t::binary >>, acc, replacement, sol) do
    parse_string_literal(t, acc, replacement, sol)
  end
  defp parse_string_literal(<< "\""::utf8, t::binary >>, acc, replacement, sol) do
    parse_code(t, acc <> ~s("), replacement, sol)
  end
  defp parse_string_literal(<< "\n"::utf8, t::binary >>, acc, replacement, sol) do
    parse_string_literal(t, acc <> "\n", replacement, true)
  end
  defp parse_string_literal(<< _::utf8, t::binary >>, acc, replacement, true) do
    parse_string_literal(t, acc <> replacement, replacement, true)
  end
  defp parse_string_literal(<< h::utf8, t::binary >>, acc, replacement, false) do
    parse_string_literal(t, acc <> << h::utf8 >>, replacement, false)
  end

  for {_sigil_start, sigil_end} <- @all_string_sigils do
    defp parse_string_sigil("", acc, unquote(sigil_end), _replacement, sol) do
      acc
    end
    defp parse_string_sigil(<< "\\\\"::utf8, t::binary >>, acc, unquote(sigil_end), replacement, sol) do
      parse_string_sigil(t, acc, unquote(sigil_end), replacement, sol)
    end
    defp parse_string_sigil(<< "\\\""::utf8, t::binary >>, acc, unquote(sigil_end), replacement, sol) do
      parse_string_sigil(t, acc, unquote(sigil_end), replacement, sol)
    end
    defp parse_string_sigil(<< unquote(sigil_end)::utf8, t::binary >>, acc, unquote(sigil_end), replacement, sol) do
      parse_code(t, acc <> unquote(sigil_end), replacement, sol)
    end
    defp parse_string_sigil(<< "\n"::utf8, t::binary >>, acc, unquote(sigil_end), replacement, sol) do
      parse_string_sigil(t, acc <> "\n", unquote(sigil_end), replacement, sol)
    end
    defp parse_string_sigil(<< _::utf8, t::binary >>, acc, unquote(sigil_end), replacement, true) do
      parse_string_sigil(t, acc <> replacement, unquote(sigil_end), replacement, true)
    end
    defp parse_string_sigil(<< h::utf8, t::binary >>, acc, unquote(sigil_end), replacement, false) do
      parse_string_sigil(t, acc <> << h::utf8 >>, unquote(sigil_end), replacement, false)
    end
  end

  defp parse_heredoc("", acc, _replacement, sol) do
    acc
  end
  defp parse_heredoc(<< "\\\\"::utf8, t::binary >>, acc, replacement, sol) do
    parse_heredoc(t, acc, replacement, sol)
  end
  defp parse_heredoc(<< "\\\""::utf8, t::binary >>, acc, replacement, sol) do
    parse_heredoc(t, acc, replacement, sol)
  end
  defp parse_heredoc(<< "\"\"\""::utf8, t::binary >>, acc, replacement, sol) do
    parse_code(t, acc <> ~s("""), replacement, sol)
  end
  defp parse_heredoc(<< "\n"::utf8, t::binary >>, acc, replacement, sol) do
    parse_heredoc(t, acc <> "\n", replacement, sol)
  end
  defp parse_heredoc(<< _::utf8, t::binary >>, acc, replacement, true) do
    parse_heredoc(t, acc <> replacement, replacement, true)
  end
  defp parse_heredoc(<< h::utf8, t::binary >>, acc, replacement, false) do
    parse_heredoc(t, acc <> << h::utf8 >>, replacement, false)
  end
end
