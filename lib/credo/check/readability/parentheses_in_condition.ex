defmodule Credo.Check.Readability.ParenthesesInCondition do
  use Credo.Check,
    base_priority: :high,
    tags: [:formatter],
    explanations: [
      check: """
      Because `if` and `unless` are macros, the preferred style is to not use
      parentheses around conditions.

          # preferred

          if valid?(username) do
            # ...
          end

          # NOT preferred

          if( valid?(username) ) do
            # ...
          end

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @doc false
  @impl true
  # TODO: consider for experimental check front-loader (tokens)
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    source_file
    |> Credo.Code.to_tokens()
    |> collect_parenthetical_tokens([], nil)
    |> find_issues([], issue_meta)
  end

  defp collect_parenthetical_tokens([], acc, _), do: acc

  defp collect_parenthetical_tokens([head | t], acc, prev_head) do
    acc =
      case check_for_opening_paren(head, t, prev_head) do
        false -> acc
        token -> acc ++ [token]
      end

    collect_parenthetical_tokens(t, acc, head)
  end

  defp check_for_opening_paren(
         {:identifier, _, if_or_unless} = start,
         [{:"(", _} = next_token | t],
         prev_head
       )
       when if_or_unless in [:if, :unless] do
    check_for_closing_paren(start, next_token, t, prev_head)
  end

  defp check_for_opening_paren(
         {:paren_identifier, _, if_or_unless},
         _,
         {:arrow_op, _, :|>}
       )
       when if_or_unless in [:if, :unless] do
    false
  end

  defp check_for_opening_paren(
         {:paren_identifier, _, if_or_unless} = token,
         [{:"(", _} | t],
         _
       )
       when if_or_unless in [:if, :unless] do
    if Enum.any?(collect_paren_children(t), &is_do/1) do
      false
    else
      token
    end
  end

  defp check_for_opening_paren(_, _, _), do: false

  # matches:  if( something ) do
  #                         ^^^^
  defp check_for_closing_paren(start, {:do, _}, _tail, {:")", _}) do
    start
  end

  # matches:  if( something ) == something_else do
  #                           ^^
  defp check_for_closing_paren(_start, {:")", _}, [{:comp_op, _, _} | _tail], _prev_head) do
    false
  end

  # matches:  if( something ) or something_else do
  #                           ^^
  defp check_for_closing_paren(_start, {:")", _}, [{:or_op, _, _} | _tail], _prev_head) do
    false
  end

  # matches:  if( something ) and something_else do
  #                           ^^^
  defp check_for_closing_paren(_start, {:")", _}, [{:and_op, _, _} | _tail], _prev_head) do
    false
  end

  # matches:  if( something ) in something_else do
  #                           ^^
  defp check_for_closing_paren(_start, {:")", _}, [{:in_op, _, _} | _tail], _prev_head) do
    false
  end

  # matches:  if( 1 + foo ) / bar > 0 do
  #                         ^
  defp check_for_closing_paren(_start, {:")", _}, [{:mult_op, _, _} | _tail], _prev_head) do
    false
  end

  # matches:  if( 1 + foo ) + bar > 0 do
  #                         ^
  defp check_for_closing_paren(_start, {:")", _}, [{:dual_op, _, _} | _tail], _prev_head) do
    false
  end

  # matches:  if( 1 &&& foo ) > bar do
  #                           ^
  defp check_for_closing_paren(_start, {:")", _}, [{:rel_op, _, _} | _tail], _prev_head) do
    false
  end

  # matches:  if( something ), do:
  #                         ^^
  defp check_for_closing_paren(start, {:",", _}, _, {:")", _}) do
    start
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

  defp is_do({_, _, :do}), do: true
  defp is_do(_), do: false

  defp collect_paren_children(x) do
    {_, children} = Enum.reduce(x, {0, []}, &collect_paren_child/2)
    children
  end

  defp collect_paren_child({:"(", _}, {nest_level, tokens}), do: {nest_level + 1, tokens}

  defp collect_paren_child({:")", _}, {nest_level, tokens}), do: {nest_level - 1, tokens}

  defp collect_paren_child(token, {0, tokens}), do: {0, tokens ++ [token]}
  defp collect_paren_child(_, {_, _} = state), do: state

  defp find_issues([], acc, _issue_meta) do
    acc
  end

  defp find_issues([{_, {line_no, _, _}, trigger} | t], acc, issue_meta) do
    new_issue = issue_for(issue_meta, line_no, trigger)

    acc = acc ++ [new_issue]

    find_issues(t, acc, issue_meta)
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "The condition of `#{trigger}` should not be wrapped in parentheses.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
