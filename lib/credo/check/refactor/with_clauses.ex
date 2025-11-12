defmodule Credo.Check.Refactor.WithClauses do
  use Credo.Check,
    id: "EX4029",
    base_priority: :high,
    explanations: [
      check: ~S"""
      `with` statements are useful when you need to chain a sequence
      of pattern matches, stopping at the first one that fails.

      But sometimes, we go a little overboard with them (pun intended).

      If the first or last clause in a `with` statement is not a `<-` clause,
      it still compiles and works, but is not really utilizing what the `with`
      macro provides and can be misleading.

          with ref = make_ref(),
               {:ok, user} <- User.create(ref),
               :ok <- send_email(user),
               Logger.debug("Created user: #{inspect(user)}") do
            user
          end

      Here, both the first and last clause are actually not matching anything.

      If we move them outside of the `with` (the first ones) or inside the body
      of the `with` (the last ones), the code becomes more focused and .

      This `with` should be refactored like this:

          ref = make_ref()

          with {:ok, user} <- User.create(ref),
               :ok <- send_email(user) do
            Logger.debug("Created user: #{inspect(user)}")
            user
          end
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:with, meta, [_, _ | _] = clauses_and_body} = ast, ctx)
       when is_list(clauses_and_body) do
    # If clauses_and_body is a list with at least two elements in it, we think
    # this might be a call to the special form "with". To be sure of that,
    # we get the last element of clauses_and_body and check that it's a keyword
    # list with a :do key in it (the body).

    # We can hard-match on [maybe_body] here since we know that clauses_and_body
    # has at least two elements.
    {maybe_clauses, [maybe_body]} = Enum.split(clauses_and_body, -1)

    if Keyword.keyword?(maybe_body) and Keyword.has_key?(maybe_body, :do) do
      {ast, put_issue(ctx, issues_for_with(maybe_clauses, meta[:line], ctx))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issues_for_with(clauses, line, ctx) do
    issue_if_not_starting_with_pattern_clause(clauses, line, ctx) ++
      issue_if_not_ending_with_pattern_clause(clauses, line, ctx)
  end

  defp issue_if_not_starting_with_pattern_clause(
         [{:<-, _meta, _args} | _rest],
         _line,
         _ctx
       ) do
    []
  end

  defp issue_if_not_starting_with_pattern_clause(_clauses, line, ctx) do
    [
      format_issue(ctx,
        message:
          "`with` doesn't start with a <- clause, move the non-pattern <- clauses outside of the `with`.",
        trigger: "with",
        line_no: line
      )
    ]
  end

  defp issue_if_not_ending_with_pattern_clause(clauses, line, ctx) do
    if length(clauses) > 1 and not match?({:<-, _, _}, Enum.at(clauses, -1)) do
      [
        format_issue(ctx,
          message:
            "`with` doesn't end with a <- clause, move the non-pattern <- clauses inside the body of the `with`.",
          trigger: "with",
          line_no: line
        )
      ]
    else
      []
    end
  end
end
