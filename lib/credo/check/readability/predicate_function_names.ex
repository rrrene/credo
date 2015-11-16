defmodule Credo.Check.Readability.PredicateFunctionNames do
  @moduledoc """
  Predicate functions/macros should be named accordingly:

  * For functions, they should end in a question mark.

      # okay

      defp user?(cookie) do
      end

      defp has_attachment?(mail) do
      end

      # not okay

      defp is_user?(cookie) do
      end

      defp is_user(cookie) do
      end

  * For guard-safe macros they should have the prefix `is_` and not end in a question mark.

  Like all `Readability` issues, this one is not a technical concern.
  But you can improve the odds of others reading and liking your code by making
  it easier to follow.
  """

  @explanation [check: @moduledoc]
  @def_ops Application.get_env(:credo, :def_ops)

  use Credo.Check, base_priority: :high

  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.traverse(source_file, &traverse(&1, &2, issue_meta))
  end

  for op <- @def_ops do
    defp traverse({unquote(op) = op, _meta, arguments} = ast, issues, issue_meta) do
      {ast, issues_for_definition(op, arguments, issues, issue_meta)}
    end
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issues_for_definition(op, body, issues, issue_meta) do
    case Enum.at(body, 0) do
      {name, meta, nil} ->
        issues_for_name(op, name, meta, issues, issue_meta)
      _ ->
        issues
    end
  end

  def issues_for_name(_op, name, meta, issues, issue_meta) do
    name = name |> to_string
    cond do
      String.starts_with?(name, "is_") && String.ends_with?(name, "?") ->
        [issue_for(:predicate_and_question_mark, meta[:line], name, issue_meta) | issues]
      String.starts_with?(name, "is_") ->
        [issue_for(:only_predicate, meta[:line], name, issue_meta) | issues]
      true ->
        issues
    end
  end

  defp issue_for(_, line_no, trigger, issue_meta) do
    format_issue issue_meta,
      message: "Predicate function names should end in a question mark.",
      trigger: trigger,
      line_no: line_no
  end
end
