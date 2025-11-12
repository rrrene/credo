defmodule Credo.Check.Readability.StringSigils do
  alias Credo.Code.Heredocs
  alias Credo.SourceFile

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
    ctx = Context.build(source_file, params, __MODULE__)

    case remove_heredocs_and_convert_to_ast(source_file) do
      {:ok, ast} ->
        result = Credo.Code.prewalk(ast, &walk/2, ctx)
        result.issues

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

  defp walk(
         {maybe_sigil, meta, [str | rest_ast]} = ast,
         ctx
       ) do
    line_no = meta[:line]

    cond do
      sigil?(maybe_sigil) ->
        {rest_ast, ctx}

      is_binary(str) ->
        maximum_allowed_quotes = ctx.params.maximum_allowed_quotes

        issue =
          if too_many_quotes?(str, maximum_allowed_quotes) do
            issue_for(ctx, line_no, str, maximum_allowed_quotes)
          end

        {
          rest_ast,
          put_issue(ctx, issue)
        }

      true ->
        {ast, ctx}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp sigil?(maybe_sigil) when is_atom(maybe_sigil) do
    maybe_sigil
    |> Atom.to_string()
    |> String.starts_with?("sigil_")
  end

  defp sigil?(_), do: false

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

  defp issue_for(ctx, line_no, trigger, maximum_allowed_quotes) do
    format_issue(
      ctx,
      message:
        "More than #{maximum_allowed_quotes} quotes found inside string literal, consider using a sigil instead.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
