defmodule Credo.Check.Readability.SpaceAfterCommas do
  @moduledoc """
  Don't use spaces after commas.

      # good
      alias Project.{Alpha, Beta}
      arr = [1, 2, 3, 4, 5]
      def some_func(first, second, third) do
        ...
      end

      # hard to read
      alias Project.{Alpha,Beta}
      arr = [1,2,3,4,5]
      def some_func(first,second,third) do
        ...
      end

  To make your code more readable put spaces or newlines after your commas.
  """

  @explanation [check: @moduledoc]
  @unspaced_commas ~r/(\,\S)/

  use Credo.Check, base_priority: :low
  alias Credo.Check.CodeHelper
  alias Credo.Code

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> CodeHelper.clean_strings_sigils_and_comments
    |> Code.to_lines
    |> Enum.flat_map(&find_issues(issue_meta, &1))
  end

  defp issue_for(issue_meta, trigger, line_no, column) do
    format_issue issue_meta,
      message: "Space missing after comma",
      trigger: trigger,
      line_no: line_no,
      column: column
  end

  defp find_issues(issue_meta, {line_no, line}) do
    @unspaced_commas
    |> Regex.scan(line, capture: :all_but_first, return: :index)
    |> List.flatten
    |> Enum.map(fn({idx, len}) ->
      trigger = String.slice(line, idx, len)
      issue_for(issue_meta, trigger, line_no, idx + 1)
    end)
  end
end
