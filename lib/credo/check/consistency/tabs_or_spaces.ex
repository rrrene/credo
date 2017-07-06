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

  @collector Credo.Check.Consistency.TabsOrSpaces.Collector

  use Credo.Check, run_on_all: true, base_priority: :high

  @doc false
  def run(source_files, exec, params \\ []) when is_list(source_files) do
    @collector.find_and_append_issues(source_files, exec, params, &issues_for/3)
  end

  defp issues_for(expected, source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    lines_with_issues =
      @collector.find_locations_not_matching(expected, source_file)

    Enum.map(lines_with_issues, fn(line_no) ->
      format_issue issue_meta,
        message: message_for(expected), line_no: line_no
    end)
  end

  defp message_for(:spaces = _expected) do
    "File is using tabs while most of the files use spaces for indentation."
  end
  defp message_for(:tabs = _expected) do
    "File is using spaces while most of the files use tabs for indentation."
  end
end
