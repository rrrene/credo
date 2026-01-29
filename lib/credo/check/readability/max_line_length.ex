defmodule Credo.Check.Readability.MaxLineLength do
  use Credo.Check,
    id: "EX3007",
    base_priority: :low,
    tags: [:formatter],
    param_defaults: [
      max_length: 120,
      ignore_definitions: true,
      ignore_heredocs: true,
      ignore_specs: false,
      ignore_sigils: true,
      ignore_strings: true,
      ignore_urls: true
    ],
    explanations: [
      check: """
      Checks for the length of lines.

      Ignores function definitions and (multi-)line strings by default.

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """,
      params: [
        max_length: "The maximum number of characters a line may consist of.",
        ignore_definitions: "Set to `true` to ignore lines including function definitions.",
        ignore_specs: "Set to `true` to ignore lines including `@spec`s.",
        ignore_sigils: "Set to `true` to ignore lines that are sigils, e.g. regular expressions.",
        ignore_strings: "Set to `true` to ignore lines that are strings or in heredocs.",
        ignore_urls: "Set to `true` to ignore lines that contain urls."
      ]
    ]

  import CredoTokenizer.Guards

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    max_length = Params.get(params, :max_length, __MODULE__)

    ignore_definitions = Params.get(params, :ignore_definitions, __MODULE__)

    ignore_specs = Params.get(params, :ignore_specs, __MODULE__)
    ignore_sigils = Params.get(params, :ignore_sigils, __MODULE__)
    ignore_strings = Params.get(params, :ignore_strings, __MODULE__)
    ignore_heredocs = Params.get(params, :ignore_heredocs, __MODULE__)
    ignore_urls = Params.get(params, :ignore_urls, __MODULE__)

    tokens = Credo.Code.Token.tokenize!(source_file)

    tokens_by_line =
      Enum.reduce(tokens, [[]], fn
        token, [current_line | memo] when is_eol(token) -> [[] | [[token | current_line] | memo]]
        token, [current_line | memo] -> [[token | current_line] | memo]
      end)
      |> Enum.filter(fn
        [{_type, {_line, column, _, _}, _value, _info} = _eol | _tokens] -> column > max_length
        [] -> false
      end)

    # We need fewer iterations here by reducing this to one `reduce` call

    tokens_by_line =
      if ignore_heredocs do
        Enum.reject(tokens_by_line, fn line_tokens ->
          Enum.any?(line_tokens, &match?({{:heredoc, _}, _, _, _}, &1))
        end)
      else
        tokens_by_line
      end

    tokens_by_line =
      if ignore_sigils do
        Enum.reject(tokens_by_line, fn line_tokens ->
          Enum.any?(line_tokens, &match?({{:sigil, _}, _, _, _}, &1))
        end)
      else
        tokens_by_line
      end

    tokens_by_line =
      if ignore_strings do
        Enum.reject(tokens_by_line, fn
          [_eol | [{{:string, _}, {_, column, _, _}, _, _} | _tokens]] -> column < max_length
          _ -> false
        end)
      else
        tokens_by_line
      end

    tokens_by_line =
      if ignore_urls do
        Enum.reject(tokens_by_line, fn line_tokens ->
          Enum.any?(line_tokens, fn
            {{type, _}, _, contents, _} when type in [:string, :heredoc, :atom, :comment] -> contains_url?(contents)
            _ -> false
          end)
        end)
      else
        tokens_by_line
      end

    tokens_by_line =
      if ignore_specs do
        Enum.reject(tokens_by_line, fn line_tokens ->
          match?(
            [{{:at_op, nil}, _, :@, nil} | [{{:identifier, nil}, _, :spec, nil} | _tokens]],
            Enum.reverse(line_tokens)
          )
        end)
      else
        tokens_by_line
      end

    tokens_by_line =
      if ignore_definitions do
        Enum.reject(tokens_by_line, fn line_tokens ->
          match?(
            [{{:identifier, nil}, _, :def, nil} | [{{:paren_identifier, nil}, _, _, nil} | _tokens]],
            Enum.reverse(line_tokens)
          )
        end)
      else
        tokens_by_line
      end

    Enum.reduce(tokens_by_line, [], fn
      [{_type, {line, column, _, _}, _value, _info} = _eol | _tokens], issues ->
        if column > max_length do
          [issue_for(issue_meta, line, column, max_length) | issues]
        else
          issues
        end

      _, issues ->
        issues
    end)
  end

  defp contains_url?("" <> contents) do
    url_regex = ~r/[-a-zA-Z0-9@:%._\+~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:%_\+.~#?&\/\/=]*)/

    String.match?(contents, url_regex)
  end

  defp contains_url?([_ | _] = contents), do: Enum.any?(contents, &contains_url?/1)
  defp contains_url?([]), do: false

  defp contains_url?({_, _, [_ | _] = contents, _}), do: Enum.any?(contents, &contains_url?/1)
  defp contains_url?({_, _, _, _}), do: false

  defp issue_for(issue_meta, line_no, line_length, max_length) do
    column = max_length + 1
    actual_length = line_length - 1
    trigger = SourceFile.line_at(IssueMeta.source_file(issue_meta), line_no, column, line_length)

    format_issue(
      issue_meta,
      message: "Line is too long (max is #{max_length}, was #{actual_length}).",
      line_no: line_no,
      column: column,
      trigger: trigger
    )
  end
end
