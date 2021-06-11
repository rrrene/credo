defmodule Credo.Check.Readability.PredicateFunctionNames do
  use Credo.Check,
    base_priority: :high,
    explanations: [
      check: """
      Predicate functions/macros should be named accordingly:

      * For functions, they should end in a question mark.

          # preferred

          defp user?(cookie) do
          end

          defp has_attachment?(mail) do
          end

          # NOT preferred

          defp is_user?(cookie) do
          end

          defp is_user(cookie) do
          end

      * For guard-safe macros they should have the prefix `is_` and not end in a question mark.

          # preferred

          defmacro is_user(cookie) do
          end

          # NOT preferred

          defmacro is_user?(cookie) do
          end

          defmacro user?(cookie) do
          end

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @def_ops [:def, :defp, :defmacro]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # TODO: consider for experimental check front-loader (ast)
  # NOTE: see below for how we want to avoid `defp = "my_variable"` definitions
  for op <- @def_ops do
    # catch variables named e.g. `defp`
    defp traverse({unquote(op), _meta, nil} = ast, issues, _issue_meta) do
      {ast, issues}
    end

    defp traverse(
           {unquote(op) = op, _meta, arguments} = ast,
           issues,
           issue_meta
         ) do
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

  defp issues_for_name(_op, name, meta, issues, issue_meta) do
    name = to_string(name)

    cond do
      String.starts_with?(name, "is_") && String.ends_with?(name, "?") ->
        [
          issue_for(issue_meta, meta[:line], name, :predicate_and_question_mark)
          | issues
        ]

      String.starts_with?(name, "is_") ->
        [issue_for(issue_meta, meta[:line], name, :only_predicate) | issues]

      true ->
        issues
    end
  end

  defp issue_for(issue_meta, line_no, trigger, _) do
    format_issue(
      issue_meta,
      message:
        "Predicate function names should not start with 'is', and should end in a question mark.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
