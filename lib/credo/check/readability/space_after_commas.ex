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

  use Credo.Check
  alias Credo.IssueMeta
  alias Credo.SourceFile

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file.source
    |> Credo.Code.to_tokens
    |> Enum.chunk(2, 1)
    |> Enum.filter(&comma_and_next/1)
    |> collect_issues([], issue_meta)
  end

  defp comma_and_next([{:",", {_, _, _}}, _] = args) do
    args
  end
  defp comma_and_next([_, _]) do
    false
  end

  defp collect_issues([], acc, _issue_meta), do: acc
  defp collect_issues([[{:",", {line_no, column1, column2}}, next_token] | rest], acc, issue_meta) when is_tuple(next_token) do
    acc = case token_location(next_token) do
      {^line_no, ^column2, _} ->
        [issue_for(issue_meta, line_no, column1, next_token) | acc]
      _ -> acc
    end
    collect_issues(rest, acc, issue_meta)
  end
  defp collect_issues([_ | rest], acc, issue_meta), do: collect_issues(rest, acc, issue_meta)

  defp issue_for(issue_meta, line_no, column, next_token) do
    trigger = "," <> token_text(issue_meta, next_token)

    format_issue issue_meta,
      message: "Space missing after comma",
      trigger: trigger,
      line_no: line_no,
      column: column
  end

  defp token_text(issue_meta, token) do
    {line_no, column1, column2} = token_location(token)

    issue_meta
    |> IssueMeta.source_file
    |> SourceFile.line_at(line_no, column1, column2)
  end

  defp token_location(token), do: elem(token, 1)
end
