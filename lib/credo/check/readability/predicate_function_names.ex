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
    issue_meta = IssueMeta.for(source_file, params)

    issue_candidates = Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))

    if issue_candidates == [] do
      []
    else
      impl_list = Credo.Code.prewalk(source_file, &find_impls(&1, &2))

      issue_candidates
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
    block_args
    |> Enum.reduce([], &do_find_impls_in_block/2)
  end

  defp do_find_impls_in_block({:@, _, [{:impl, _, [impl]}]}, acc) when impl != false do
    [:record_next_definition | acc]
  end

  # def when
  defp do_find_impls_in_block({keyword, meta, [{:when, _, def_ast} | _]}, [
         :record_next_definition | impls
       ])
       when keyword in @def_ops do
    do_find_impls_in_block({keyword, meta, def_ast}, [:record_next_definition | impls])
  end

  # def 0 arity
  defp do_find_impls_in_block({keyword, _meta, [{name, _, nil} | _]}, [
         :record_next_definition | impls
       ])
       when keyword in @def_ops do
    [{to_string(name), 0} | impls]
  end

  # def n arity
  defp do_find_impls_in_block({keyword, _meta, [{name, _, args} | _]}, [
         :record_next_definition | impls
       ])
       when keyword in @def_ops do
    [{to_string(name), length(args)} | impls]
  end

  defp do_find_impls_in_block(_, acc) do
    acc
  end

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
      {ast, issues_candidate_for_definition(op, arguments, issues, issue_meta)}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issues_candidate_for_definition(op, [{name, meta, nil} | _], issues, issue_meta) do
    issues_candidate_for_definition(op, [{name, meta, []}], issues, issue_meta)
  end

  defp issues_candidate_for_definition(op, [{name, meta, args} | _], issues, issue_meta) do
    issues_candidate_for_name(op, name, meta, issues, issue_meta, args)
  end

  defp issues_candidate_for_definition(_op, _, issues, _issue_meta) do
    issues
  end

  defp issues_candidate_for_name(
         _op,
         {:unquote, _, [_ | _]} = _name,
         _meta,
         issues,
         _issue_meta,
         _args
       ) do
    issues
  end

  defp issues_candidate_for_name(op, name, meta, issues, issue_meta, args) do
    name = to_string(name)

    cond do
      String.starts_with?(name, "is_") && String.ends_with?(name, "?") ->
        [
          issue_candidate_for(issue_meta, meta[:line], name, args, :predicate_and_question_mark)
          | issues
        ]

      String.starts_with?(name, "is_") && op != :defmacro ->
        [issue_candidate_for(issue_meta, meta[:line], name, args, :only_predicate) | issues]

      true ->
        issues
    end
  end

  defp issue_candidate_for(issue_meta, line_no, trigger, args, _) do
    {format_issue(
       issue_meta,
       message:
         "Predicate function names should not start with 'is', and should end in a question mark.",
       trigger: trigger,
       line_no: line_no
     ), {trigger, length(args)}}
  end
end
