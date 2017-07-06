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
    issue_meta = IssueMeta.for(source_file, params)
    issue_locations =
      expected
      |> @collector.find_locations_not_matching(source_file)
      |> Enum.reject(&ignored?(&1[:trigger], params))
      |> Enum.filter(&create_issue?(&1, issue_meta))

    Enum.map(issue_locations, fn(location) ->
      format_issue issue_meta,
        message: message_for(expected), line_no: location[:line_no],
        column: location[:column], trigger: location[:trigger]
    end)
  end

  defp message_for(:with_space = _expected) do
    "There are spaces around operators most of the time, but not here."
  end
  defp message_for(:without_space = _expected) do
    "There are no spaces around operators most of the time, but here there are."
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
  # TODO: Consider moving these checks inside the Collector.
  defp create_issue?(line, column, operator) when operator in [:+, :-] do
    !number_with_sign?(line, column) &&
      !number_in_range?(line, column) &&
      !(operator == :- && minus_in_binary_size?(line, column))
  end
  defp create_issue?(_, _, _), do: true

  defp number_with_sign?(line, column) do
    line
    |> String.slice(0..column - 2) # -2 because we need to subtract the operator
    |> String.match?(~r/(\A\s+|\@[a-zA-Z0-9\_]+|[\|\\\{\[\(\,\:\>\<\=\+\-\*\/])\s*$/)
  end

  defp number_in_range?(line, column) do
    line
    |> String.slice(column..-1)
    |> String.match?(~r/^\d+\.\./)
  end

  # TODO: this implementation is a bit naive. improve it.
  defp minus_in_binary_size?(line, column) do
    binary_pattern_start_before? =
      line
      |> String.slice(0..column - 2) # -2 because we need to subtract the operator
      |> String.match?(~r/\<\</)

    double_colon_before? =
      line
      |> String.slice(0..column - 2) # -2 because we need to subtract the operator
      |> String.match?(~r/\:\:/)

    binary_pattern_end_after? =
      line
      |> String.slice(column..-1) # -1 because we need to subtract the operator
      |> String.match?(~r/\>\>/)

    typed_after? =
      line
      |> String.slice(column..-1) # -1 because we need to subtract the operator
      |> String.match?(~r/^\s*(integer|native|signed|unsigned|binary|size|little|float)/)

    typed_before? =
      line
      |> String.slice(0..column - 2) # -2 because we need to subtract the operator
      |> String.match?(~r/(integer|native|signed|unsigned|binary|size|little|float)\s*$/)

    heuristics_met_count =
      [
        binary_pattern_start_before?,
        binary_pattern_end_after?,
        double_colon_before?,
        typed_after?,
        typed_before?
      ]
      |> Enum.filter(&(&1))
      |> Enum.count

    heuristics_met_count >= 2
  end
end
