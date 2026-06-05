defmodule Credo.Check.Refactor.WithAssignment do
  use Credo.Check,
    base_priority: :high,
    category: :refactor,
    explanations: [
      check: ~S"""
      `with` statements are designed for chaining pattern matches using the `<-` operator.
      Using regular assignment (`=`) inside a `with` block defeats its purpose and can be misleading.

      When you use `=` in a `with` block, the assignment always succeeds and doesn't provide
      the early-exit behavior that makes `with` useful.

      Example of incorrect usage:

          with user = get_user(id),
               {:ok, profile} <- get_profile(user),
               settings = get_settings(user) do
            {:ok, %{user: user, profile: profile, settings: settings}}
          end

      In this example, `user = get_user(id)` and `settings = get_settings(user)` will always
      succeed, even if the functions return `nil` or an error tuple.

      This should be refactored to either:

      1. Move assignments outside the `with`:

          user = get_user(id)
          settings = get_settings(user)

          with {:ok, profile} <- get_profile(user) do
            {:ok, %{user: user, profile: profile, settings: settings}}
          end

      2. Or use pattern matching if you need to handle failures:

          with {:ok, user} <- get_user(id),
               {:ok, profile} <- get_profile(user),
               {:ok, settings} <- get_settings(user) do
            {:ok, %{user: user, profile: profile, settings: settings}}
          end
      """
    ]

  @message_assignment_in_with "Avoid using `=` in `with` blocks. Use `<-` for pattern matching or move assignments outside the `with`."

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:with, _meta, [_, _ | _] = clauses_and_body} = ast, issues, issue_meta)
       when is_list(clauses_and_body) do
    # Split off the last element which should be the body (keyword list with :do)
    {maybe_clauses, [maybe_body]} = Enum.split(clauses_and_body, -1)

    if Keyword.keyword?(maybe_body) and Keyword.has_key?(maybe_body, :do) do
      new_issues = check_clauses_for_assignments(maybe_clauses, issue_meta)
      {ast, new_issues ++ issues}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp check_clauses_for_assignments(clauses, issue_meta) do
    Enum.flat_map(clauses, fn clause ->
      case clause do
        {:=, meta, _args} ->
          [
            format_issue(issue_meta,
              message: @message_assignment_in_with,
              line_no: meta[:line],
              trigger: "="
            )
          ]

        _ ->
          []
      end
    end)
  end
end
