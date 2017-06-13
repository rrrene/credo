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

  use Credo.Check, base_priority: :high, elixir_version: ">= 1.3.2"

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    min_number = Params.get(params, :only_greater_than, @default_params)

    source_file
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
  defp find_issues([{:number, {line_no, column1, _column2} = location, number} | t], acc, issue_meta) do
    source = source_fragment(location, issue_meta)
    underscored_number = number_with_underscores(number, source)
    new_issue =
      if decimal_in_source?(source) && source != underscored_number do
        [issue_for(
          issue_meta, line_no, column1, source, underscored_number
        )]
      else
        []
      end

    acc = acc ++ new_issue

    find_issues(t, acc, issue_meta)
  end

  defp number_with_underscores(number, _) when is_integer(number) do
    number
    |> to_string
    |> add_underscores_to_number_string
  end
  defp number_with_underscores(number, source_fragment) when is_number(number) do
    case String.split(source_fragment, ".", parts: 2) do
      [num, decimal] ->
        Enum.join([add_underscores_to_number_string(num), decimal], ".")
      [num] ->
        add_underscores_to_number_string(num)
    end
  end

  defp add_underscores_to_number_string(string) do
    string
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

  defp decimal_in_source?(source) do
    case String.slice(source, 0, 2) do
      "0b" -> false
      "0o" -> false
      "0x" -> false
      _ -> true
    end
  end

  defp source_fragment({line_no, column1, column2} = tuple, issue_meta) do
    fragment =
      issue_meta
      |> IssueMeta.source_file
      |> SourceFile.line_at(line_no)
      |> String.slice((column1 - 1)..(column2 - 1))
      |> Credo.Backports.String.trim
      |> String.replace(~r/\D$/, "")

    if Version.match?(System.version, "< 1.3.2-dev") do
      source_fragment_pre_132(tuple, issue_meta, fragment)
    else
      fragment
    end
  end

  # There's a bug in the :elixir_tokenizer.tokenize/3 in versions prior to
  # 1.3.2 where the _ in the source code is not included in the token's
  # length, so that means we have to re-calculate the token if it has _ in it.
  #
  # Unfortuately this leaves the line and column counts out of sync so this
  # "fix" only works "reliably" for the first number with _ in the line.
  defp source_fragment_pre_132({line_no, column1, column2}, issue_meta, first_fragment) do
    underscores = (first_fragment |> String.split("_") |> Enum.count) - 1

    if underscores > 0 do
      issue_meta
      |> IssueMeta.source_file
      |> SourceFile.line_at(line_no)
      |> String.slice((column1 - 1)..(column2 - 2 + underscores))
      |> Credo.Backports.String.trim
      |> String.replace(~r/\D$/, "")
    else
      first_fragment
    end
  end
end
