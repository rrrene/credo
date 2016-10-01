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
    |> collect_parenthetical_tokens([], nil)
    |> find_issues([], issue_meta)
  end

  defp collect_parenthetical_tokens([], acc, _), do: acc
  defp collect_parenthetical_tokens([head | t], acc, prev_head) do
    acc =
      case parenthetical_condition?(head, t, prev_head) do
        nil -> acc
        false -> acc
        token -> acc ++ [token]
      end

    collect_parenthetical_tokens(t, acc, head)
  end

  defp parenthetical_condition?({:identifier, _, :if} = start, [next_token | t],
                                prev_head) do
    parenthetical_grouped_condition?(start, next_token, t, prev_head)
  end
  defp parenthetical_condition?({:identifier, _, :unless} = start, [next_token | t],
                                prev_head) do
    parenthetical_grouped_condition?(start, next_token, t, prev_head)
  end
  defp parenthetical_condition?({:paren_identifier, _, :if}, _,
                                {:arrow_op, _, :|>}) do
    false
  end
  defp parenthetical_condition?({:paren_identifier, _, :if} = token, _,
                                _prev_head) do
    token
  end
  defp parenthetical_condition?({:paren_identifier, _, :unless}, _,
                                {:arrow_op, _, :|>}) do
    false
  end
  defp parenthetical_condition?({:paren_identifier, _, :unless} = token, _,
                                _prev_head) do
    token
  end
  defp parenthetical_condition?(_, _, _), do: false

  defp parenthetical_grouped_condition?(token, {:do, _}, _, {:")", _}) do
    token
  end
  defp parenthetical_grouped_condition?(token, {:",", _}, _, {:")", _}) do
    token
  end
  defp parenthetical_grouped_condition?(_, {:or_op, _, _}, [{:"(",  _} | _], _) do
     false
  end
  defp parenthetical_grouped_condition?(_, {:and_op, _, _}, [{:"(", _} | _], _) do
     false
  end
  defp parenthetical_grouped_condition?(_, {:comp_op, _, _}, [{:"(", _} | _], _) do
     false
  end
  defp parenthetical_grouped_condition?(start, token, [next_token | t], _) do
     parenthetical_grouped_condition?(start, next_token, t, token)
  end
  defp parenthetical_grouped_condition?(_, _, _, _) do
    false
  end

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
