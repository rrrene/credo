defmodule Credo.Check.Consistency.ExceptionNames do
  @moduledoc """
  Exception names should end with a common suffix like "Error".

  Try to name your exception modules consistently:

      defmodule BadCodeError do
        defexception [:message]
      end

      defmodule ParserError do
        defexception [:message]
      end

  Inconsistent use should be avoided:

      defmodule BadHTTPResponse do
        defexception [:message]
      end

      defmodule HTTPHeaderException do
        defexception [:message]
      end

  While this is not necessarily a concern for the correctness of your code,
  you should use a consistent style throughout your codebase.
  """

  @explanation [check: @moduledoc]

  @collector Credo.Check.Consistency.ExceptionNames.Collector

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
        [{:message, message_for(expected, location[:trigger])} | location]
    end)
  end

  defp message_for({:prefix, expected}, trigger) do
    message =
      """
      Exception modules should be named consistently.
      It seems your strategy is to prefix them with `#{expected}`,
      but `#{trigger}` does not follow that convention."
      """

    to_one_line(message)
  end
  defp message_for({:suffix, expected}, trigger) do
    message =
      """
      Exception modules should be named consistently.
      It seems your strategy is to have `#{expected}` as a suffix,
      but `#{trigger}` does not follow that convention.
      """

    to_one_line(message)
  end

  def to_one_line(str) do
    str
    |> String.split
    |> Enum.join(" ")
  end
end
