defmodule Credo.Check.Readability.VariableNames do
  use Credo.Check,
    id: "EX3031",
    base_priority: :high,
    explanations: [
      check: """
      Variable names are always written in snake_case in Elixir.

          # snake_case:

          incoming_result = handle_incoming_message(message)

          # not snake_case

          incomingResult = handle_incoming_message(message)

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ],
    managed_traversal: :ast

  alias Credo.Code.Name

  @special_var_names [:__CALLER__, :__DIR__, :__ENV__, :__MODULE__]

  def handle_walk({:=, _meta, [lhs, _rhs]} = ast, ctx) do
    {ast, issues_for_lhs(lhs, ctx)}
  end

  def handle_walk({:->, _meta, [lhs, _rhs]} = ast, ctx) do
    {ast, issues_for_lhs(lhs, ctx)}
  end

  def handle_walk({:<-, _meta, [lhs, _rhs]} = ast, ctx) do
    {ast, issues_for_lhs(lhs, ctx)}
  end

  def handle_walk({:def, _meta, [{_fun, _fun_meta, [lhs, _rhs]}, _fun_rhs]} = ast, ctx) do
    {ast, issues_for_lhs(lhs, ctx)}
  end

  def handle_walk({:defp, _meta, [{_fun, _fun_meta, [lhs, _rhs]}, _fun_rhs]} = ast, ctx) do
    {ast, issues_for_lhs(lhs, ctx)}
  end

  def handle_walk(ast, ctx) do
    {ast, ctx}
  end

  for op <- [:{}, :%{}, :^, :|, :<>] do
    defp issues_for_lhs({unquote(op), _meta, parameters}, ctx) do
      issues_for_lhs(parameters, ctx)
    end
  end

  defp issues_for_lhs({_name, _meta, nil} = value, ctx) do
    case issue_for_name(value, ctx) do
      nil -> ctx
      new_issue -> put_issue(ctx, new_issue)
    end
  end

  defp issues_for_lhs(list, ctx) when is_list(list) do
    Enum.reduce(list, ctx, &issues_for_lhs/2)
  end

  defp issues_for_lhs(tuple, ctx) when is_tuple(tuple) do
    Enum.reduce(Tuple.to_list(tuple), ctx, &issues_for_lhs/2)
  end

  defp issues_for_lhs(_, ctx) do
    ctx
  end

  for name <- @special_var_names do
    defp issue_for_name({unquote(name), _, nil}, _), do: nil
  end

  defp issue_for_name({name, meta, nil}, ctx) do
    string_name = to_string(name)

    unless Name.snake_case?(string_name) or Name.no_case?(string_name) do
      issue_for(ctx, meta, name)
    end
  end

  defp issue_for(ctx, meta, trigger) do
    format_issue(
      ctx,
      message: "Variable names should be written in snake_case.",
      trigger: trigger,
      line_no: meta[:line]
    )
  end
end
