defmodule Credo.Check.Readability.StringSigils do
  alias Credo.SourceFile
  alias Credo.Code.Heredocs

  use Credo.Check,
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

    case remove_heredocs_and_convert_to_ast(source_file) do
      {:ok, ast} ->
        Credo.Code.prewalk(ast, &traverse(&1, &2, issue_meta, maximum_allowed_quotes))

      {:error, errors} ->
        IO.warn("Unexpected error while parsing #{source_file.filename}: #{inspect(errors)}")
        []
    end
  end

  defp remove_heredocs_and_convert_to_ast(source_file) do
    source_file
    |> Heredocs.replace_with_spaces()
    |> Credo.Code.ast()
  end

  defp traverse(
         {maybe_sigil, meta, [str | rest_ast]} = ast,
         issues,
         issue_meta,
         maximum_allowed_quotes
       ) do
    line_no = meta[:line]

    cond do
      is_sigil(maybe_sigil) ->
        {rest_ast, issues}

      is_binary(str) ->
        {
          rest_ast,
          issues_for_string_literal(
            str,
            maximum_allowed_quotes,
            issues,
            issue_meta,
            line_no
          )
        }

      true ->
        {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta, _maximum_allowed_quotes) do
    {ast, issues}
  end

  defp is_sigil(maybe_sigil) when is_atom(maybe_sigil) do
    maybe_sigil
    |> Atom.to_string()
    |> String.starts_with?("sigil_")
  end

  defp is_sigil(_), do: false

  defp issues_for_string_literal(
         string,
         maximum_allowed_quotes,
         issues,
         issue_meta,
         line_no
       ) do
    if too_many_quotes?(string, maximum_allowed_quotes) do
      [issue_for(issue_meta, line_no, string, maximum_allowed_quotes) | issues]
    else
      issues
    end
  end

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
