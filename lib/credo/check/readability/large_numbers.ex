defmodule Credo.Check.Readability.LargeNumbers do
  use Credo.Check,
    base_priority: :high,
    tags: [:formatter],
    param_defaults: [
      only_greater_than: 9_999
    ],
    explanations: [
      check: """
      Numbers can contain underscores for readability purposes.
      These do not affect the value of the number, but can help read large numbers
      more easily.

          141592654 # how large is this number?

          141_592_654 # ah, it's in the hundreds of millions!

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """,
      params: [
        only_greater_than: "The check only reports numbers greater than this."
      ]
    ]

  @doc false
  # TODO: consider for experimental check front-loader (tokens)
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    min_number = Params.get(params, :only_greater_than, __MODULE__)

    source_file
    |> Credo.Code.to_tokens()
    |> collect_number_tokens([], min_number)
    |> find_issues([], issue_meta)
  end

  defp collect_number_tokens([], acc, _), do: acc

  defp collect_number_tokens([head | t], acc, min_number) do
    acc =
      case number_token(head, min_number) do
        nil -> acc
        token -> acc ++ [token]
      end

    collect_number_tokens(t, acc, min_number)
  end

  # tuple for Elixir >= 1.10.0
  defp number_token({:flt, {_, _, number}, _} = tuple, min_number) when min_number < number do
    tuple
  end

  # tuple for Elixir >= 1.6.0
  defp number_token({:int, {_, _, number}, _} = tuple, min_number) when min_number < number do
    tuple
  end

  defp number_token({:float, {_, _, number}, _} = tuple, min_number) when min_number < number do
    tuple
  end

  # tuple for Elixir <= 1.5.x
  defp number_token({:number, _, number} = tuple, min_number) when min_number < number do
    tuple
  end

  defp number_token(_, _), do: nil

  defp find_issues([], acc, _issue_meta) do
    acc
  end

  # tuple for Elixir >= 1.10.0
  defp find_issues(
         [{:flt, {line_no, column1, number} = location, _} | t],
         acc,
         issue_meta
       ) do
    acc = acc ++ find_issue(line_no, column1, location, number, issue_meta)

    find_issues(t, acc, issue_meta)
  end

  # tuple for Elixir >= 1.6.0
  defp find_issues(
         [{:int, {line_no, column1, number} = location, _} | t],
         acc,
         issue_meta
       ) do
    acc = acc ++ find_issue(line_no, column1, location, number, issue_meta)

    find_issues(t, acc, issue_meta)
  end

  defp find_issues(
         [{:float, {line_no, column1, number} = location, _} | t],
         acc,
         issue_meta
       ) do
    acc = acc ++ find_issue(line_no, column1, location, number, issue_meta)

    find_issues(t, acc, issue_meta)
  end

  # tuple for Elixir <= 1.5.x
  defp find_issues(
         [{:number, {line_no, column1, _column2} = location, number} | t],
         acc,
         issue_meta
       ) do
    acc = acc ++ find_issue(line_no, column1, location, number, issue_meta)

    find_issues(t, acc, issue_meta)
  end

  defp find_issue(line_no, column1, location, number, issue_meta) do
    source = source_fragment(location, issue_meta)
    underscored_number = number_with_underscores(number, source)

    if decimal_in_source?(source) && source != underscored_number do
      [
        issue_for(
          issue_meta,
          line_no,
          column1,
          source,
          underscored_number
        )
      ]
    else
      []
    end
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
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1_")
    |> String.reverse()
  end

  defp issue_for(issue_meta, line_no, column, trigger, expected) do
    format_issue(
      issue_meta,
      message: "Large numbers should be written with underscores: #{expected}",
      line_no: line_no,
      column: column,
      trigger: trigger
    )
  end

  defp decimal_in_source?(source) do
    case String.slice(source, 0, 2) do
      "0b" -> false
      "0o" -> false
      "0x" -> false
      "" -> false
      _ -> true
    end
  end

  defp source_fragment({line_no, column1, _}, issue_meta) do
    line =
      issue_meta
      |> IssueMeta.source_file()
      |> SourceFile.line_at(line_no)

    beginning_of_number =
      ~r/[^0-9_oxb]*([0-9_oxb]+$)/
      |> Regex.run(String.slice(line, 1..column1))
      |> List.wrap()
      |> List.last()
      |> to_string()

    ending_of_number =
      ~r/^([0-9_\.]+)/
      |> Regex.run(String.slice(line, (column1 + 1)..-1))
      |> List.wrap()
      |> List.last()
      |> to_string()
      |> String.replace(~r/\.\..*/, "")

    beginning_of_number <> ending_of_number
  end
end
