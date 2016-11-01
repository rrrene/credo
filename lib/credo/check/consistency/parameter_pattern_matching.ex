defmodule Credo.Check.Consistency.ParameterPatternMatching do
  @moduledoc """
  When capturing a parameter using pattern matching you can either put the name before or after the value
  i.e.
    def parse({:ok, values} = pair)

    or

    def parse(pair = {:ok, values})

  While this is not necessarily a concern for the correctness of your code,
  you should use a consistent style throughout your codebase.
  """


  @explanation [check: @moduledoc]
  @code_patterns [
    Credo.Check.Consistency.ParameterPatternMatching.PositionCollector
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

  defp message_for(:after) do
    "the variable name after the pattern"
  end

  defp message_for(:before) do
    "the variable name before the pattern"
  end

  defp issue_for(_issue_meta, _actual_props, nil, _picked_count, _total_count), do: nil
  defp issue_for(_issue_meta, [], _expected_prop, _picked_count, _total_count), do: nil
  defp issue_for(issue_meta, actual_prop, expected_prop, _picked_count, _total_count) do
    line_no = PropertyValue.meta(actual_prop, :line_no)
    actual_prop = PropertyValue.get(actual_prop)
    format_issue issue_meta,
      message: "File has #{message_for(actual_prop)} while most of the files have #{message_for(expected_prop)} when naming parameter pattern matches",
      line_no: line_no
  end
end
