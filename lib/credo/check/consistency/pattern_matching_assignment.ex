defmodule Credo.Check.Consistency.PatternMatchingAssignment do
  @moduledoc """
  Both left and right pattern matching assigments of Map arguments on function call are valid -

  def show(conn, %{"messenger" => messenger} = params) do
  # ...
  end

  as well as

  def show(conn, params = %{"messenger" => messenger}) do
  # ...
  end

  It is preferable to keep it consistent, using same approach everywhere
  """

  @explanation [check: @moduledoc]

  @code_patterns [
    Credo.Check.Consistency.PatternMatchingAssignment.LeftSideAssignment,
    Credo.Check.Consistency.PatternMatchingAssignment.RightSideAssignment
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
    trigger = PropertyValue.meta(actual_prop, :trigger)

    actual_prop = PropertyValue.get(actual_prop)
    format_issue issue_meta,
      message: "File is using #{actual_prop} map pattern matching assignments while most of the files use #{expected_prop} assignments endings.",
      line_no: line_no,
      trigger: trigger
  end
end
