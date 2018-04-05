defmodule Credo.Check.Consistency.SpaceAroundOperators do
  @moduledoc """
  Use spaces around operators like `+`, `-`, `*` and `/`. This is the
  **preferred** way, although other styles are possible, as long as it is
  applied consistently.

      # preferred

      1 + 2 * 4

      # also okay

      1+2*4

  While this is not necessarily a concern for the correctness of your code,
  you should use a consistent style throughout your codebase.
  """

  @explanation [check: @moduledoc]

  @collector Credo.Check.Consistency.SpaceAroundOperators.Collector

  @default_params [ignore: [:|]]

  use Credo.Check, run_on_all: true, base_priority: :high

  # TODO: add *ignored* operators, so you can add "|" and still write
  #       [head|tail] while enforcing 2 + 3 / 1 ...
  # FIXME: this seems to be already implemented, but there don't seem to be
  # any related test cases around.

  @doc false
  def run(source_files, exec, params \\ []) when is_list(source_files) do
    @collector.find_and_append_issues(source_files, exec, params, &issues_for/3)
  end

  defp issues_for(expected, source_file, params) do
    tokens = Credo.Code.to_tokens(source_file)
    ast = SourceFile.ast(source_file)
    issue_meta = IssueMeta.for(source_file, params)

    issue_locations =
      expected
      |> @collector.find_locations_not_matching(source_file)
      |> Enum.reject(&ignored?(&1, params))
      |> Enum.filter(&create_issue?(&1, tokens, ast, issue_meta))

    Enum.map(issue_locations, fn location ->
      format_issue(
        issue_meta,
        message: message_for(expected),
        line_no: location[:line_no],
        column: location[:column],
        trigger: location[:trigger]
      )
    end)
  end

  defp message_for(:with_space = _expected) do
    "There are spaces around operators most of the time, but not here."
  end

  defp message_for(:without_space = _expected) do
    "There are no spaces around operators most of the time, but here there are."
  end

  defp ignored?(location, params) do
    ignored_triggers = Params.get(params, :ignore, @default_params)

    Enum.member?(ignored_triggers, location[:trigger])
  end

  defp create_issue?(location, tokens, ast, issue_meta) do
    line_no = location[:line_no]

    line =
      issue_meta
      |> IssueMeta.source_file()
      |> SourceFile.line_at(line_no)

    if create_issue?(line, location[:column], location[:trigger]) do
      create_issue_really?(location, tokens, ast, issue_meta)
    end
  end

  # Don't create issues for `c = -1`
  # TODO: Consider moving these checks inside the Collector.
  defp create_issue?(line, column, trigger) when trigger in [:+, :-] do
    !number_with_sign?(line, column) && !number_in_range?(line, column) &&
      !(trigger == :- && minus_in_binary_size?(line, column))
  end

  defp create_issue?(line, column, trigger) when trigger == :-> do
    !arrow_in_typespec?(line, column)
  end

  defp create_issue?(line, column, trigger) when trigger == :/ do
    !number_in_fun?(line, column)
  end

  defp create_issue?(_, _, _), do: true

  defp arrow_in_typespec?(line, column) do
    # -2 because we need to subtract the operator
    line
    |> String.slice(0..(column - 2))
    |> String.match?(~r/\(\s*$/)
  end

  defp number_with_sign?(line, column) do
    # -2 because we need to subtract the operator
    line
    |> String.slice(0..(column - 2))
    |> String.match?(~r/(\A\s+|\@[a-zA-Z0-9\_]+|[\|\\\{\[\(\,\:\>\<\=\+\-\*\/])\s*$/)
  end

  defp number_in_range?(line, column) do
    line
    |> String.slice(column..-1)
    |> String.match?(~r/^\d+\.\./)
  end

  defp number_in_fun?(line, column) do
    line
    |> String.slice(0..(column - 2))
    |> String.match?(~r/[\.\&][a-z0-9_]+$/)
  end

  # TODO: this implementation is a bit naive. improve it.
  defp minus_in_binary_size?(line, column) do
    # -2 because we need to subtract the operator
    binary_pattern_start_before? =
      line
      |> String.slice(0..(column - 2))
      |> String.match?(~r/\<\</)

    # -2 because we need to subtract the operator
    double_colon_before? =
      line
      |> String.slice(0..(column - 2))
      |> String.match?(~r/\:\:/)

    # -1 because we need to subtract the operator
    binary_pattern_end_after? =
      line
      |> String.slice(column..-1)
      |> String.match?(~r/\>\>/)

    # -1 because we need to subtract the operator
    typed_after? =
      line
      |> String.slice(column..-1)
      |> String.match?(~r/^\s*(integer|native|signed|unsigned|binary|size|little|float)/)

    # -2 because we need to subtract the operator
    typed_before? =
      line
      |> String.slice(0..(column - 2))
      |> String.match?(~r/(integer|native|signed|unsigned|binary|size|little|float)\s*$/)

    heuristics_met_count =
      [
        binary_pattern_start_before?,
        binary_pattern_end_after?,
        double_colon_before?,
        typed_after?,
        typed_before?
      ]
      |> Enum.filter(& &1)
      |> Enum.count()

    heuristics_met_count >= 2
  end

  defp create_issue_really?(location, tokens, ast, issue_meta) do
    result = find_current_prev_next_token(tokens, location)
    # |> IO.inspect(label: "tokens")

    find_ast_elements(ast, result)
    # |> IO.inspect(label: "ast")

    # analyse_ast_and_tokens_together

    true
  end

  # TOKENS

  defp find_current_prev_next_token(tokens, location) do
    location_tuple = {location[:line_no], location[:column], location[:trigger]}

    # IO.inspect(location_tuple, label: "location_tuple")

    [result] =
      tokens
      |> traverse_prev_current_next(&matching_location(location_tuple, &1, &2, &3, &4), [])

    result
  end

  defp traverse_prev_current_next(tokens, callback, acc) do
    tokens
    |> case do
      [prev | [current | [next | rest]]] ->
        acc = callback.(prev, current, next, acc)

        traverse_prev_current_next([current | [next | rest]], callback, acc)

      _ ->
        acc
    end
  end

  defp matching_location(
         {line_no, column, trigger},
         prev,
         {_, {line_no, column, _}, trigger} = current,
         next,
         acc
       ) do
    acc ++ [{prev, current, next}]
  end

  defp matching_location(_, _prev, _current, _next, acc) do
    acc
  end

  # AST

  defp find_ast_elements(ast, {prev, current, next}) do
    position = Credo.Code.Token.position(current)

    Credo.Code.prewalk(ast, &find_token(&1, &2, current, position), [])
  end

  defp find_token(
         {_, meta, _} = ast,
         acc,
         token,
         {line_no_start, _col_start, line_no_end, _col_end}
       ) do
    if meta[:line] >= line_no_start and meta[:line] <= line_no_end do
      if ast_matches_token?(ast, token) do
        {ast, acc ++ [ast]}
      else
        {ast, acc}
      end
    else
      {ast, acc}
    end
  end

  defp find_token(ast, acc, _token, _position) do
    {ast, acc}
  end

  defp ast_matches_token?({atom, _, _} = ast, {_, _, atom} = token) do
    # this is not enough, since there could be many :+ or :- in a single line
    # we have to find the exact match
    true
  end

  defp ast_matches_token?(ast, token) do
    IO.inspect(ast, label: "ast")
    IO.inspect(token, label: "token")
    IO.puts("")

    false
  end
end
