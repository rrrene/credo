defmodule Credo.Check.Consistency.LineEndings do
  @moduledoc """
  Windows and *nix systems use different line-endings in files.

  While this is not necessarily a concern for the correctness of your code,
  you should use a consistent style throughout your codebase.
  """

  @explanation [check: @moduledoc]

  @collector Credo.Check.Consistency.LineEndings.Collector

  use Credo.Check, run_on_all: true, base_priority: :high

  @doc false
  def run(source_files, exec, params \\ []) when is_list(source_files) do
    source_files
    |> @collector.find_issues(params, &issues_for/2)
    |> Enum.uniq
    |> Enum.each(&(@collector.insert_issue(&1, exec)))

    :ok
  end

  defp issues_for(expected, {[actual], source_file, params}) do
    source_file
    |> IssueMeta.for(params)
    |> format_issue(message: "File is using #{actual} line endings\
while most of the files use #{expected} line endings.")
    |> List.wrap
  end
end
