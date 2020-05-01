defmodule Credo.Check.Readability.VariableNames do
  use Credo.Check,
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
    ]

  alias Credo.Code.Name

  @special_var_names [:__CALLER__, :__DIR__, :__ENV__, :__MODULE__]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:=, _meta, [lhs, _rhs]} = ast, issues, issue_meta) do
    {ast, issues_for_lhs(lhs, issues, issue_meta)}
  end

  defp traverse({:->, _meta, [lhs, _rhs]} = ast, issues, issue_meta) do
    {ast, issues_for_lhs(lhs, issues, issue_meta)}
  end

  defp traverse(
         {:<-, _meta, [{:|, _comp_meta, [_lhs, rhs]}, _comp_rhs]} = ast,
         issues,
         issue_meta
       ) do
    {ast, issues_for_lhs(rhs, issues, issue_meta)}
  end

  defp traverse({:<-, _meta, [lhs, _rhs]} = ast, issues, issue_meta) do
    {ast, issues_for_lhs(lhs, issues, issue_meta)}
  end

  defp traverse(
         {:def, _meta, [{_fun, _fun_meta, [lhs, _rhs]}, _fun_rhs]} = ast,
         issues,
         issue_meta
       ) do
    {ast, issues_for_lhs(lhs, issues, issue_meta)}
  end

  defp traverse(
         {:defp, _meta, [{_fun, _fun_meta, [lhs, _rhs]}, _fun_rhs]} = ast,
         issues,
         issue_meta
       ) do
    {ast, issues_for_lhs(lhs, issues, issue_meta)}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  for op <- [:{}, :%{}, :^, :|, :<>] do
    defp issues_for_lhs({unquote(op), _meta, parameters}, issues, issue_meta) do
      issues_for_lhs(parameters, issues, issue_meta)
    end
  end

  defp issues_for_lhs({_name, _meta, nil} = value, issues, issue_meta) do
    case issue_for_name(value, issue_meta) do
      nil ->
        issues

      new_issue ->
        [new_issue | issues]
    end
  end

  defp issues_for_lhs(list, issues, issue_meta) when is_list(list) do
    Enum.reduce(list, issues, &issues_for_lhs(&1, &2, issue_meta))
  end

  defp issues_for_lhs(tuple, issues, issue_meta) when is_tuple(tuple) do
    Enum.reduce(
      Tuple.to_list(tuple),
      issues,
      &issues_for_lhs(&1, &2, issue_meta)
    )
  end

  defp issues_for_lhs(_, issues, _issue_meta) do
    issues
  end

  for name <- @special_var_names do
    defp issue_for_name({unquote(name), _, nil}, _), do: nil
  end

  defp issue_for_name({name, meta, nil}, issue_meta) do
    string_name = to_string(name)

    unless Name.snake_case?(string_name) or Name.no_case?(string_name) do
      issue_for(issue_meta, meta[:line], name)
    end
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Variable names should be written in snake_case.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
