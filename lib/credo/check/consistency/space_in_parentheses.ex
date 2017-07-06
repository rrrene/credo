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
    @collector.find_and_append_issues(source_files, exec, params, &issues_for/3)
  end

  defp issues_for(expected, source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    lines_with_issues =
      @collector.find_locations_not_matching(expected, source_file)

    lines_with_issues
    |> Enum.filter(&create_issue?(expected, &1[:trigger]))
    |> Enum.map(fn(location) ->
        format_issue issue_meta,
          [{:message, message_for(expected)} | location]
      end)
  end

  # Don't create issues for `&Mod.fun/4`
  defp create_issue?(:without_space, ", ]"), do: false
  defp create_issue?(_expected, _trigger), do: true

  defp message_for(:without_space = _expected) do
    "There is no whitespace around parentheses/brackets most of the time, but here there is."
  end
  defp message_for(:with_space = _expected) do
    "There is whitespace around parentheses/brackets most of the time, but here there is not."
  end
end
