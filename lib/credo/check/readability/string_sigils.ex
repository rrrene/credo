defmodule Credo.Check.Readability.StringSigils do
  @moduledoc ~S"""
  If you used quoted strings that contain quotes, you might want to consider
  switching to the use of sigils instead.

      # okay

      "<a href=\"http://elixirweekly.net\">#\{text}</a>"

      # not okay, lots of escaped quotes

      "<a href=\"http://elixirweekly.net\" target=\"_blank\">#\{text}</a>"

      # refactor to

      ~S(<a href="http://elixirweekly.net" target="_blank">#\{text}</a>)

  This allows us to remove the noise which results from the need to escape
  quotes within quotes.
  """

  @explanation [
    check: @moduledoc,
    params: [
      maximum_allowed_quotes: "The maximum amount of escaped quotes you want to tolerate."
    ]
  ]
  @default_params [
    maximum_allowed_quotes: 3
  ]
  @quote_codepoint 34

  use Credo.Check, base_priority: :low

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    maximum_allowed_quotes = Params.get(params, :maximum_allowed_quotes, @default_params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, maximum_allowed_quotes))
  end

  def traverse({_sigil, [terminator: _, line: _], [_ | rest_ast]}, issues, _issue_meta, _maximum_allowed_quotes) do
    {rest_ast, issues}
  end
  def traverse({maybe_sigil, [line: line_no], [str | rest_ast]} = ast, issues, issue_meta, maximum_allowed_quotes) do
    cond do
      is_sigil(maybe_sigil) ->
        {rest_ast, issues}
      is_binary(str) ->
        {rest_ast, issues_for_string_literal(str, maximum_allowed_quotes, issues, issue_meta, line_no)}
      true ->
        {ast, issues}
    end
  end
  def traverse(ast, issues, _issue_meta, _maximum_allowed_quotes) do
    {ast, issues}
  end

  defp is_sigil(maybe_sigil) when is_atom(maybe_sigil) do
    maybe_sigil
    |> Atom.to_string
    |> String.starts_with?("sigil_")
  end
  defp is_sigil(_), do: false

  defp issues_for_string_literal(string, maximum_allowed_quotes, issues, issue_meta, line_no) do
    if !is_heredoc(issue_meta, line_no) && too_many_quotes?(string, maximum_allowed_quotes) do
      [issue_for(issue_meta, line_no, string, maximum_allowed_quotes) | issues]
    else
      issues
    end
  end

  defp is_heredoc({_, source_file, _}, line_no) do
    lines = SourceFile.lines(source_file)
    {_, line} = Enum.find(lines, fn {n, _} -> n == line_no end)

    Regex.match?(~r/"""$/, line)
  end

  defp too_many_quotes?(string, limit) do
    too_many_quotes?(string, 0, limit)
  end

  defp too_many_quotes?(_string, count, limit) when count > limit do
    true
  end
  defp too_many_quotes?(<<>>, _count,  _limit) do
    false
  end
  defp too_many_quotes?(<<c::utf8, rest::binary>>, count, limit) when c == @quote_codepoint do
    too_many_quotes?(rest, count + 1, limit)
  end
  defp too_many_quotes?(<<_::utf8, rest::binary>>, count, limit) do
    too_many_quotes?(rest, count, limit)
  end

  defp issue_for(issue_meta, line_no, trigger, maximum_allowed_quotes) do
    format_issue issue_meta,
      message: "More than #{maximum_allowed_quotes} quotes found inside string literal, consider using a sigil instead.",
      trigger: trigger,
      line_no: line_no
  end
end
