defmodule Credo.Check.Consistency.ParameterPatternMatching do
  use Credo.Check,
    run_on_all: true,
    base_priority: :high,
    explanations: [
      check: """
      When capturing a parameter using pattern matching you can either put the parameter name before or after the value
      i.e.

          def parse({:ok, values} = pair)

      or

          def parse(pair = {:ok, values})

      Neither of these is better than the other, but it seems a good idea not to mix the two patterns in the same codebase.

      While this is not necessarily a concern for the correctness of your code,
      you should use a consistent style throughout your codebase.
      """
    ]

  @collector Credo.Check.Consistency.ParameterPatternMatching.Collector

  @doc false
  @impl true
  def run_on_all_source_files(exec, source_files, params) do
    @collector.find_and_append_issues(source_files, exec, params, &issues_for/3)
  end

  defp issues_for(expected, source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    issue_locations = @collector.find_locations_not_matching(expected, source_file)

    Enum.map(issue_locations, fn location ->
      format_issue(issue_meta, [{:message, message_for(expected)} | location])
    end)
  end

  defp message_for(expected) do
    actual = @collector.actual_for(expected)

    "File has #{message_for_kind(actual)} while most of the files " <>
      "have #{message_for_kind(expected)} when naming parameter pattern matches"
  end

  defp message_for_kind(:after), do: "the variable name after the pattern"
  defp message_for_kind(:before), do: "the variable name before the pattern"
end
