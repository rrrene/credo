defmodule Credo.Check.Readability.WithSingleClause do
  use Credo.Check,
    id: "EX3033",
    explanations: [
      check: ~S"""
      `with` statements are useful when you need to chain a sequence
      of pattern matches, stopping at the first one that fails.

      If the `with` has a single pattern matching clause and no `else`
      branch, it means that if the clause doesn't match than the whole
      `with` will return the value of that clause.

      However, if that `with` has also an `else` clause, then you're using `with` exactly
      like a `case` and a `case` should be used instead.

      Take this code:

          with {:ok, user} <- User.create(make_ref()) do
            user
          else
            {:error, :db_down} ->
              raise "DB is down!"

            {:error, reason} ->
              raise "error: #{inspect(reason)}"
          end

      It can be rewritten with a clearer use of `case`:

          case User.create(make_ref()) do
            {:ok, user} ->
              user

            {:error, :db_down} ->
              raise "DB is down!"

            {:error, reason} ->
              raise "error: #{inspect(reason)}"
          end

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  alias Credo.Code.Block

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({:with, meta, [_, _ | _] = clauses_and_body} = ast, ctx) do
    if Block.do_block?(ast) && Block.else_block?(ast) do
      {clauses, [_body]} = Enum.split(clauses_and_body, -1)

      contains_unquote_splicing? = Enum.any?(clauses, &match?({:unquote_splicing, _, _}, &1))
      pattern_clauses_count = Enum.count(clauses, &match?({:<-, _, _}, &1))

      if contains_unquote_splicing? == false && pattern_clauses_count <= 1 do
        {ast, put_issue(ctx, issue_for(meta, ctx))}
      else
        {ast, ctx}
      end
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(meta, ctx) do
    format_issue(ctx,
      message:
        "`with` contains only one <- clause and an `else` branch, consider using `case` instead",
      trigger: "with",
      line_no: meta[:line]
    )
  end
end
