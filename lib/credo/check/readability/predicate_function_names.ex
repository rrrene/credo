defmodule Credo.Check.Readability.PredicateFunctionNames do
  use Credo.Check,
    id: "EX3016",
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
    ctx = Context.build(source_file, params, __MODULE__, %{issue_candidates: []})
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)

    if result.issue_candidates == [] do
      []
    else
      impl_list = Credo.Code.prewalk(source_file, &find_impls(&1, &2))

      result.issue_candidates
      |> Enum.reject(fn {_, signature} -> signature in impl_list end)
      |> Enum.map(fn {issue, _} -> issue end)
    end
  end

  defp find_impls({:__block__, _meta, args} = ast, impls) do
    block_impls = find_impls_in_block(args)
    {ast, block_impls ++ impls}
  end

  defp find_impls(ast, impls) do
    {ast, impls}
  end

  defp find_impls_in_block(block_args) when is_list(block_args) do
    Enum.reduce(block_args, [], &do_find_impls_in_block/2)
  end

  defp do_find_impls_in_block({:@, _, [{:impl, _, [impl]}]}, acc) when impl != false do
    [:record_next_definition | acc]
  end

  # def when
  defp do_find_impls_in_block({op, meta, [{:when, _, def_ast} | _]}, [
         :record_next_definition | impls
       ])
       when op in @def_ops do
    do_find_impls_in_block({op, meta, def_ast}, [:record_next_definition | impls])
  end

  # def 0 arity
  defp do_find_impls_in_block({op, _meta, [{name, _, nil} | _]}, [
         :record_next_definition | impls
       ])
       when op in @def_ops do
    [{to_string(name), 0} | impls]
  end

  # def n arity
  defp do_find_impls_in_block({op, _meta, [{name, _, args} | _]}, [
         :record_next_definition | impls
       ])
       when op in @def_ops do
    [{to_string(name), length(args)} | impls]
  end

  defp do_find_impls_in_block(_, acc) do
    acc
  end

  for op <- @def_ops do
    # catch variables named e.g. `defp`
    defp walk({unquote(op), _meta, nil} = ast, ctx) do
      {ast, ctx}
    end

    defp walk({unquote(op) = op, _meta, [{name, meta, nil} | _]} = ast, ctx) do
      {ast, issues_candidate_for_name(op, name, meta, ctx, [])}
    end

    defp walk({unquote(op) = op, _meta, [{name, meta, args} | _]} = ast, ctx) do
      {ast, issues_candidate_for_name(op, name, meta, ctx, args)}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issues_candidate_for_name(_, {:unquote, _, [_ | _]}, _, ctx, _) do
    ctx
  end

  defp issues_candidate_for_name(op, name, meta, ctx, args) do
    name = to_string(name)

    cond do
      String.starts_with?(name, "is_") && String.ends_with?(name, "?") ->
        unshift(ctx, :issue_candidates, issue_candidate_for(ctx, meta, name, args))

      String.starts_with?(name, "is_") && op != :defmacro ->
        unshift(ctx, :issue_candidates, issue_candidate_for(ctx, meta, name, args))

      true ->
        ctx
    end
  end

  defp issue_candidate_for(ctx, meta, trigger, args) do
    {format_issue(
       ctx,
       message:
         "Predicate function names should not start with 'is', and should end in a question mark.",
       trigger: trigger,
       line_no: meta[:line]
     ), {trigger, length(args)}}
  end
end
