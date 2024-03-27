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

    impl_list = Credo.Code.prewalk(source_file, &find_impls(&1, &2))

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, impl_list))
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
    [:impl | acc]
  end

  # def when
  defp do_find_impls_in_block({keyword, meta, [{:when, _, def_ast} | _]}, [:impl | impls])
       when keyword in @def_ops do
    do_find_impls_in_block({keyword, meta, def_ast}, [:impl | impls])
  end

  # def 0 arity
  defp do_find_impls_in_block({keyword, _meta, [{name, _, nil} | _]}, [:impl | impls])
       when keyword in @def_ops do
    [{name, 0} | impls]
  end

  # def n arity
  defp do_find_impls_in_block({keyword, _meta, [{name, _, args} | _]}, [:impl | impls])
       when keyword in @def_ops do
    [{name, length(args)} | impls]
  end

  defp do_find_impls_in_block(_, acc) do
    acc
  end

  for op <- @def_ops do
    # catch variables named e.g. `defp`
    defp traverse({unquote(op), _meta, nil} = ast, issues, _issue_meta, _impl_list) do
      {ast, issues}
    end

    defp traverse(
           {unquote(op) = op, _meta, arguments} = ast,
           issues,
           issue_meta,
           impl_list
         ) do
      {ast, issues_for_definition(op, arguments, issues, issue_meta, impl_list)}
    end
  end

  defp traverse(ast, issues, _issue_meta, _impl_list) do
    {ast, issues}
  end

  defp issues_for_definition(op, [{name, meta, nil} | _], issues, issue_meta, impl_list) do
    issues_for_definition(op, [{name, meta, []}], issues, issue_meta, impl_list)
  end

  defp issues_for_definition(op, [{name, meta, args} | _], issues, issue_meta, impl_list) do
    if {name, length(args)} in impl_list do
      issues
    else
      issues_for_name(op, name, meta, issues, issue_meta)
    end
  end

  defp issues_for_definition(_op, _, issues, _issue_meta, _impl_list) do
    issues
  end

  defp issues_for_name(_op, {:unquote, _, [_ | _]} = _name, _meta, issues, _issue_meta) do
    issues
  end

  defp issues_for_name(op, name, meta, issues, issue_meta) do
    name = to_string(name)

    cond do
      String.starts_with?(name, "is_") && String.ends_with?(name, "?") ->
        [
          issue_for(issue_meta, meta[:line], name, :predicate_and_question_mark)
          | issues
        ]

      String.starts_with?(name, "is_") && op != :defmacro ->
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
