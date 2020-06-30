defmodule Credo.Check.Consistency.SpaceAroundOperators do
  use Credo.Check,
    run_on_all: true,
    base_priority: :high,
    tags: [:formatter],
    param_defaults: [ignore: [:|]],
    explanations: [
      check: """
      Use spaces around operators like `+`, `-`, `*` and `/`. This is the
      **preferred** way, although other styles are possible, as long as it is
      applied consistently.

          # preferred

          1 + 2 * 4

          # also okay

          1+2*4

      While this is not necessarily a concern for the correctness of your code,
      you should use a consistent style throughout your codebase.
      """,
      params: [
        ignore: "List of operators to be ignored for this check."
      ]
    ]

  @collector Credo.Check.Consistency.SpaceAroundOperators.Collector

  # TODO: add *ignored* operators, so you can add "|" and still write
  #       [head|tail] while enforcing 2 + 3 / 1 ...
  # FIXME: this seems to be already implemented, but there don't seem to be
  # any related test cases around.

  @doc false
  @impl true
  def run_on_all_source_files(exec, source_files, params) do
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
    ignored_triggers = Params.get(params, :ignore, __MODULE__)

    Enum.member?(ignored_triggers, location[:trigger])
  end

  defp create_issue?(location, tokens, ast, issue_meta) do
    line_no = location[:line_no]
    trigger = location[:trigger]
    column = location[:column]

    line =
      issue_meta
      |> IssueMeta.source_file()
      |> SourceFile.line_at(line_no)

    create_issue?(trigger, line_no, column, line, tokens, ast)
  end

  defp create_issue?(trigger, line_no, column, line, tokens, ast) when trigger in [:+, :-] do
    create_issue?(line, column, trigger) &&
      !parameter_in_function_call?({line_no, column, trigger}, tokens, ast)
  end

  defp create_issue?(trigger, _line_no, column, line, _tokens, _ast) do
    create_issue?(line, column, trigger)
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
    !number_in_function_capture?(line, column)
  end

  defp create_issue?(line, _column, trigger) when trigger == :* do
    # The Elixir formatter always removes spaces around the asterisk in
    # typespecs for binaries by default. Credo shouldn't conflict with the
    # default Elixir formatter settings.
    !typespec_binary_unit_operator_without_spaces?(line)
  end

  defp create_issue?(_, _, _), do: true

  defp typespec_binary_unit_operator_without_spaces?(line) do
    # In code this construct can only appear inside a binary typespec. It could
    # also appear verbatim in a string, but it's rather unlikely...
    line =~ "_::_*"
  end

  defp arrow_in_typespec?(line, column) do
    # -2 because we need to subtract the operator
    line
    |> String.slice(0..(column - 2))
    |> String.match?(~r/\(\s*$/)
  end

  defp number_with_sign?(line, column) do
    line
    # -2 because we need to subtract the operator
    |> String.slice(0..(column - 2))
    |> String.match?(~r/(\A\s+|\@[a-zA-Z0-9\_]+\.?|[\|\\\{\[\(\,\:\>\<\=\+\-\*\/])\s*$/)
  end

  defp number_in_range?(line, column) do
    line
    |> String.slice(column..-1)
    |> String.match?(~r/^\d+\.\./)
  end

  defp number_in_function_capture?(line, column) do
    line
    |> String.slice(0..(column - 2))
    |> String.match?(~r/[\.\&][a-z0-9_]+[\!\?]?$/)
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

  defp parameter_in_function_call?(location_tuple, tokens, ast) do
    case find_prev_current_next_token(tokens, location_tuple) do
      {prev, _current, _next} ->
        prev
        |> Credo.Code.TokenAstCorrelation.find_tokens_in_ast(ast)
        |> List.wrap()
        |> List.first()
        |> is_parameter_in_function_call()

      _ ->
        false
    end
  end

  defp is_parameter_in_function_call({atom, _, arguments})
       when is_atom(atom) and is_list(arguments) do
    true
  end

  defp is_parameter_in_function_call(
         {{:., _, [{:__aliases__, _, _mods}, fun_name]}, _, arguments}
       )
       when is_atom(fun_name) and is_list(arguments) do
    true
  end

  defp is_parameter_in_function_call(_) do
    false
  end

  # TOKENS

  defp find_prev_current_next_token(tokens, location_tuple) do
    tokens
    |> traverse_prev_current_next(&matching_location(location_tuple, &1, &2, &3, &4), [])
    |> List.first()
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
end
