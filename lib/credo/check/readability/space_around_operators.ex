  defmodule Credo.Check.Readability.SpaceAroundOperators do
  @moduledoc """
  Use spaces around operators like `+`, `-`, `*` and `/`. This is the
  **preferred** way, although other styles are possible, as long as it is
  applied consistently.

      # preferred

      1 + 2 * 4

  While this is not necessarily a concern for the correctness of your code,
  you should use a consistent style throughout your codebase.
  """

  @explanation [check: @moduledoc]


  @default_params [ignore: []]

  use Credo.Check

  alias Credo.Code

  import Credo.Check.Readability.SpaceHelper,
         only: [
           expected_spaces: 1,
           space_between?: 2,
           no_space_between?: 2
         ]

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    issue_locations =
      source_file
      |> Code.to_tokens()
      |> traverse_tokens()
      |> Enum.reject(&ignored?(&1[:trigger], params))
      |> Enum.filter(&create_issue?(&1, issue_meta))

    Enum.map(issue_locations, fn location ->
      format_issue(
        issue_meta,
        message: message_for(location[:mismatch]),
        line_no: location[:line_no],
        column: location[:column],
        trigger: location[:trigger]
      )
    end)
  end

  defp traverse_tokens(tokens, acc \\ []) do
    tokens
    |> skip_function_capture
    |> case do
         [prev | [current | [next | rest]]] ->
           expected_spaces = expected_spaces(current)
           acc = record_not_matching(expected_spaces, prev, current, next, acc)
           traverse_tokens([current | [next | rest]], acc)
         _ ->
           acc
       end
  end

  defp skip_function_capture([{:capture_op, _, _} | tokens]) do
    Enum.drop_while(tokens, fn
      # :erlang_module
      {:atom, _, _} ->
        true

      # ElixirModule (Elxiir >= 1.6.0)
      {:alias, _, _} ->
        true

      # ElixirModule
      {:aliases, _, _} ->
        true

      # function_name
      {:identifier, _, _} ->
        true

      # @module_attribute
      {:at_op, _, _} ->
        true

      {:., _} ->
        true

      _ ->
        false
    end)
  end

  defp skip_function_capture(tokens), do: tokens

  defp record_not_matching(expected, prev, current, next, acc) do
    match_found =
      case expected do
        :ignore ->
          false
        :with_space ->
          without_space?(prev, current, next)
        :without_space ->
          with_space?(prev, current, next)
      end

    if match_found do
      {_, {line_no, column, _}, trigger} = current

      [[line_no: line_no, column: column, trigger: trigger, mismatch: expected] | acc]
    else
      acc
    end
  end

  defp with_space?(prev, op, next) do
    space_between?(prev, op) || space_between?(op, next)
  end

  defp without_space?(prev, op, next) do
    no_space_between?(prev, op) || no_space_between?(op, next)
  end

  defp message_for(:with_space = _expected) do
    "There should be spaces around the operator."
  end

  defp message_for(:without_space = _expected) do
    "There should be no spaces around the operator."
  end

  defp ignored?(trigger, params) do
    ignored_triggers = Params.get(params, :ignore, @default_params)
    Enum.member?(ignored_triggers, trigger)
  end

  defp create_issue?(location, issue_meta) do
    line =
      issue_meta
      |> IssueMeta.source_file()
      |> SourceFile.line_at(location[:line_no])

    create_issue?(line, location[:column], location[:trigger])
  end

  # Don't create issues for `c = -1`
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
    |> String.match?(
      ~r/(\A\s+|\@[a-zA-Z0-9\_]+|[\|\\\{\[\(\,\:\>\<\=\+\-\*\/])\s*$/
    )
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
      |> String.match?(
        ~r/^\s*(integer|native|signed|unsigned|binary|size|little|float)/
      )

    # -2 because we need to subtract the operator
    typed_before? =
      line
      |> String.slice(0..(column - 2))
      |> String.match?(
        ~r/(integer|native|signed|unsigned|binary|size|little|float)\s*$/
      )

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
end
