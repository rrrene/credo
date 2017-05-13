defmodule Credo.Check.Readability.SpaceAfterCommas do
  @moduledoc """
  You can use white-space after commas to make items of lists,
  tuples and other enumerations easier to separate from one another.

      # preferred

      alias Project.{Alpha, Beta}

      def some_func(first, second, third) do
        list = [1, 2, 3, 4, 5]
        # ...
      end

      # NOT preferred - items are harder to separate

      alias Project.{Alpha,Beta}

      def some_func(first,second,third) do
        list = [1,2,3,4,5]
        # ...
      end

  Like all `Readability` issues, this one is not a technical concern.
  But you can improve the odds of others reading and liking your code by making
  it easier to follow.
  """

  @explanation [check: @moduledoc]

  # Matches commas followed by non-whitespace unless preceded by
  # a question mark that is not part of a variable or function name
  @unspaced_commas ~r/(?<!\W\?)(\,\S)/

  use Credo.Check
  alias Credo.Check.CodeHelper
  alias Credo.Code

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> SourceFile.source
    |> CodeHelper.clean_charlists_strings_sigils_and_comments
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
