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
    @collector.find_and_append_issues(source_files, exec, params, &issues_for/3)
  end

  defp issues_for(expected, source_file, params) do
    source_file
    |> IssueMeta.for(params)
    |> format_issue(message: message_for(expected))
    |> List.wrap
  end

  defp message_for(:unix = _expected) do
    "File is using windows line endings while most of the files use unix line endings."
  end
  defp message_for(:windows = _expected) do
    "File is using unix line endings while most of the files use windows line endings."
  end
end
