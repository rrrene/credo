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

  @collector Credo.Check.Consistency.ParameterPatternMatching.Collector

  use Credo.Check, run_on_all: true, base_priority: :high

  @doc false
  def run(source_files, exec, params \\ []) when is_list(source_files) do
    @collector.find_and_append_issues(source_files, exec, params, &issues_for/3)
  end

  defp issues_for(expected, source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    issue_locations =
      @collector.find_locations_not_matching(expected, source_file)

    Enum.map(issue_locations, fn(location) ->
      format_issue issue_meta,
        [{:message, message_for(expected)} | location]
    end)
  end

  defp message_for(expected) do
    actual = @collector.actual_for(expected)

    "File has #{message_for_kind(actual)} while most of the files have #{message_for_kind(expected)} when naming parameter pattern matches"
  end

  defp message_for_kind(:after), do: "the variable name after the pattern"
  defp message_for_kind(:before), do: "the variable name before the pattern"
end
