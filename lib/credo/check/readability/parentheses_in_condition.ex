defmodule Credo.Check.Readability.ParenthesesInCondition do
  @moduledoc """
  Because `if` and `unless` are macros, the preferred style is to not use
  parentheses around conditions.

      # preferred way
      if valid?(username) do
        # ...
      end

      # NOT okay
      if( valid?(username) ) do
        # ...
      end

  Like all `Readability` issues, this one is not a technical concern.
  But you can improve the odds of others reading and liking your code by making
  it easier to follow.
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high

  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file.source
    |> Credo.Code.to_tokens
    |> collect_parenthetical_tokens([])
    |> find_issues([], issue_meta)
  end

  defp collect_parenthetical_tokens([], acc), do: acc
  defp collect_parenthetical_tokens([head | t], acc) do
    acc =
      case parenthetical_condition?(head, t) do
        nil -> acc
        false -> acc
        token -> acc ++ [token]
      end

    collect_parenthetical_tokens(t, acc)
  end

  defp parenthetical_condition?({:"(", _} = token) do
    {elem(token, 0), elem(token, 1), nil}
  end
  defp parenthetical_condition?(_), do: false

  defp parenthetical_condition?({:identifier, _, :if}, [next_token | _t]) do
    parenthetical_condition?(next_token)
  end
  defp parenthetical_condition?({:identifier, _, :unless}, [next_token | _t]) do
    parenthetical_condition?(next_token)
  end
  defp parenthetical_condition?({:paren_identifier, _, :if} = token, _) do
    token
  end
  defp parenthetical_condition?({:paren_identifier, _, :unless} = token, _) do
    token
  end
  defp parenthetical_condition?(_, _), do: false

  defp find_issues([], acc, _issue_meta) do
    acc
  end
  defp find_issues([{_, {line_no, _, _}, trigger} | t], acc, issue_meta) do
    new_issue = issue_for(issue_meta, line_no, trigger)

    acc = acc ++ [new_issue]

    find_issues(t, acc, issue_meta)
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "The condition of `#{trigger}` should not be wrapped in parentheses.",
      trigger: trigger,
      line_no: line_no
  end
end
