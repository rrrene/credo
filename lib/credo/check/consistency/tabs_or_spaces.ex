defmodule Credo.Check.Consistency.TabsOrSpaces do
  @moduledoc """
  Tabs should be used consistently.

  NOTE: This check does not verify the indentation depth, but checks whether
  or not soft/hard tabs are used consistently across all source files.

  It is very common to use 2 spaces wide soft-tabs, but that is not a strict
  requirement and you can use hard-tabs if you like that better.

  While this is not necessarily a concern for the correctness of your code,
  you should use a consistent style throughout your codebase.
  """

  @explanation [check: @moduledoc]
  @code_patterns [
    Credo.Check.Consistency.TabsOrSpaces.Tabs,
    Credo.Check.Consistency.TabsOrSpaces.Spaces
  ]

  alias Credo.Check.Consistency.Helper
  alias Credo.Check.PropertyValue

  use Credo.Check, run_on_all: true, base_priority: :high

  @doc false
  def run(source_files, params \\ []) when is_list(source_files) do
    source_files
    |> Helper.run_code_patterns(@code_patterns, params)
    |> Helper.append_issues_via_issue_service(&issue_for/5, params)

    :ok
  end

  defp issue_for(_issue_meta, _actual_props, nil, _picked_count, _total_count), do: nil
  defp issue_for(_issue_meta, [], _expected_prop, _picked_count, _total_count), do: nil
  defp issue_for(issue_meta, actual_prop, expected_prop, _picked_count, _total_count) do
    line_no = PropertyValue.meta(actual_prop, :line_no)
    actual_prop = PropertyValue.get(actual_prop)
    format_issue issue_meta,
      message: "File is using #{actual_prop} while most of the files use #{expected_prop} for indentation.",
      line_no: line_no
  end
end
