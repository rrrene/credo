defmodule Credo.Check.Consistency.SpaceInParentheses do
  @moduledoc """
  Don't use spaces after `(`, `[`, and `{` or before `}`, `]`, and `)`. This is
  the **preferred** way, although other styles are possible, as long as it is
  applied consistently.

      # preferred

      Helper.format({1, true, 2}, :my_atom)

      # also okay

      Helper.format( { 1, true, 2 }, :my_atom )

  While this is not necessarily a concern for the correctness of your code,
  you should use a consistent style throughout your codebase.
  """

  @explanation [check: @moduledoc]

  @collector Credo.Check.Consistency.SpaceInParentheses.Collector

  use Credo.Check, run_on_all: true, base_priority: :high

  @doc false
  def run(source_files, exec, params \\ []) when is_list(source_files) do
    source_files
    |> @collector.find_issues(params, &issues_for/2)
    |> Enum.each(&(@collector.insert_issue(&1, exec)))

    :ok
  end

  defp issues_for(expected, {[actual], source_file, params}) do
    issue_meta = IssueMeta.for(source_file, params)
    lines_with_issues = @collector.find_locations(actual, source_file)

    lines_with_issues
    |> Enum.filter(&create_issue?(expected, actual, &1[:trigger]))
    |> Enum.map(fn(location) ->
        format_issue issue_meta,
          location ++ [message: message_for(expected, actual)]
      end)
  end

  # Don't create issues for `&Mod.fun/4`
  defp create_issue?(:without_space, :with_space, ", ]"), do: false
  defp create_issue?(_expected, _actual, _trigger), do: true

  defp message_for(:without_space, :with_space) do
    "There is no whitespace around parentheses/brackets most of the time, but here there is."
  end
  defp message_for(:with_space, :without_space) do
    "There is whitespace around parentheses/brackets most of the time, but here there is not."
  end
end
