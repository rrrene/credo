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
    source_files
    |> @collector.find_issues(params, &issues_for/2)
    |> Enum.each(&(@collector.insert_issue(&1, exec)))

    :ok
  end

  defp issues_for(expected, {[actual], source_file, params}) do
    issue_meta = IssueMeta.for(source_file, params)
    issue_locations = @collector.find_locations(actual, source_file)

    Enum.map(issue_locations, fn(location) ->
      format_issue issue_meta,
        [{:message, message_for(expected, actual)} | location]
    end)
  end

  defp message_for(expected, actual) do
    "File has #{message_for(actual)} while most of the files have #{message_for(expected)} when naming parameter pattern matches"
  end

  defp message_for(:after), do: "the variable name after the pattern"
  defp message_for(:before), do: "the variable name before the pattern"
end
