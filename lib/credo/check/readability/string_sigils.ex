defmodule Credo.Check.Readability.StringSigils do
  use Credo.Check,
    id: "EX3027",
    base_priority: :low,
    param_defaults: [
      maximum_allowed_quotes: 3
    ],
    explanations: [
      check: ~S"""
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

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """,
      params: [
        maximum_allowed_quotes: "The maximum amount of escaped quotes you want to tolerate."
      ]
    ]

  @quote_codepoint 34

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    maximum_allowed_quotes = Params.get(params, :maximum_allowed_quotes, __MODULE__)

    source_file
    |> Credo.Code.Token.reduce(&collect(&1, &2, &3, &4, issue_meta, maximum_allowed_quotes))
    |> Enum.reverse()
  end

  defp collect({{:string, _}, {line_no, _, _, _}, [value], _}, _, _, acc, issue_meta, maximum_allowed_quotes)
       when is_binary(value) do
    if too_many_quotes?(value, maximum_allowed_quotes) do
      [issue_for(issue_meta, line_no, value, maximum_allowed_quotes) | acc]
    else
      acc
    end
  end

  defp collect(_prev, _current, _next, acc, _issue_meta, _maximum_allowed_quotes), do: acc

  defp too_many_quotes?(string, limit) do
    too_many_quotes?(string, 0, limit)
  end

  defp too_many_quotes?(_string, count, limit) when count > limit do
    true
  end

  defp too_many_quotes?(<<>>, _count, _limit) do
    false
  end

  defp too_many_quotes?(<<c::utf8, rest::binary>>, count, limit)
       when c == @quote_codepoint do
    too_many_quotes?(rest, count + 1, limit)
  end

  defp too_many_quotes?(<<_::utf8, rest::binary>>, count, limit) do
    too_many_quotes?(rest, count, limit)
  end

  defp too_many_quotes?(<<_::binary>>, _count, _limit) do
    false
  end

  defp issue_for(issue_meta, line_no, trigger, maximum_allowed_quotes) do
    format_issue(
      issue_meta,
      message:
        "More than #{maximum_allowed_quotes} quotes found inside string literal, consider using a sigil instead.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
