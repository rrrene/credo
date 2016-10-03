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
      case check_for_opening_paren(head, t, prev_head) do
        nil -> acc
        false -> acc
        token -> acc ++ [token]
      end

    collect_parenthetical_tokens(t, acc, head)
  end

  defp check_for_opening_paren({:identifier, _, if_or_unless} = start, [{:"(", _} = next_token | t], prev_head) when if_or_unless in [:if, :unless] do
    check_for_closing_paren(start, next_token, t, prev_head)
  end
  defp check_for_opening_paren({:paren_identifier, _, if_or_unless}, _, {:arrow_op, _, :|>}) when if_or_unless in [:if, :unless] do
    false
  end
  defp check_for_opening_paren({:paren_identifier, _, if_or_unless} = token, _, _prev_head) when if_or_unless in [:if, :unless] do
    token
  end
  defp check_for_opening_paren(_, _, _), do: false

  # matches:  if( something ) do
  #                         ^^^^
  defp check_for_closing_paren(token, {:do, _}, _, {:")", _}) do
    token
  end
  # matches:  if( something ), do:
  #                         ^^
  defp check_for_closing_paren(token, {:",", _}, _, {:")", _}) do
    token
  end
  defp check_for_closing_paren(_, {:or_op, _, _}, [{:"(", _} | _], _) do
     false
  end
  defp check_for_closing_paren(_, {:and_op, _, _}, [{:"(", _} | _], _) do
     false
  end
  defp check_for_closing_paren(_, {:comp_op, _, _}, [{:"(", _} | _], _) do
     false
  end
  defp check_for_closing_paren(start, token, [next_token | t], _prev_head) do
    check_for_closing_paren(start, next_token, t, token)
  end
  defp check_for_closing_paren(_, _, _, _), do: false


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
