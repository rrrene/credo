defmodule Credo.Check.Readability.LargeNumbers do
  @moduledoc """
  Numbers can contain underscores for readability purposes.
  These do not affect the value of the number, but can help read large numbers
  more easily.

      141592654 # how large is this number?

      141_592_654 # ah, it's in the hundreds of millions!

  Like all `Readability` issues, this one is not a technical concern.
  But you can improve the odds of others reading and liking your code by making
  it easier to follow.
  """

  @explanation [
    check: @moduledoc,
    params: [
      only_greater_than: "The check only reports numbers greater than this.",
    ]
  ]
  @default_params [
    only_greater_than: 9_999,
  ]

  use Credo.Check, base_priority: :high

  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    min_number = params |> Params.get(:only_greater_than, @default_params)

    source_file.source
    |> Credo.Code.to_tokens
    |> collect_number_tokens([], min_number)
    |> find_issues([], issue_meta)
  end

  defp collect_number_tokens([], acc, _), do: acc
  defp collect_number_tokens([head | t], acc, min_number) do
    acc =
      case number_token(head, min_number) do
        nil -> acc
        false -> acc
        token -> acc ++ [token]
      end

    collect_number_tokens(t, acc, min_number)
  end

  defp number_token({:number, _, number} = tuple, min_number) when min_number < number do
    tuple
  end
  defp number_token(_, _), do: nil

  defp find_issues([], acc, _issue_meta) do
    acc
  end
  defp find_issues([{:number, {line_no, column1, _column2}, number} | t], acc, issue_meta) do
    line =
      issue_meta
      |> IssueMeta.source_file
      |> SourceFile.line_at(line_no)

    line_ending = String.slice(line, 0..column1-1)

    underscore_count =
      Regex.run(~r/\d_\d/, line_ending)
      |> List.wrap
      |> Enum.count

    temp_string =
      line
      |> String.slice(column1-1+underscore_count..-1)

    found_string =
      ~r/([0-9\_]*\.[0-9]+|[0-9\_]+)/
      |> Regex.run(temp_string)
      |> List.first

    underscored_number = number_with_underscores(number)

    new_issue =
      cond do
        found_string != underscored_number ->
          [issue_for(issue_meta, line_no, column1, found_string, underscored_number)]
        true ->
          []
      end

    acc = acc ++ new_issue

    find_issues(t, acc, issue_meta)
  end

  defp number_with_underscores(number) do
    number
    |> to_string
    |> String.reverse
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1_")
    |> String.reverse
  end

  def issue_for(issue_meta, line_no, column, trigger, expected) do
    format_issue issue_meta,
      message: "Large numbers should be written with underscores: #{expected}",
      line_no: line_no,
      column: column,
      trigger: trigger
  end
end
