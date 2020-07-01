defmodule Credo.Check.Readability.Specs do
  use Credo.Check,
    tags: [:controversial],
    explanations: [
      check: """
      Functions, callbacks and macros need typespecs.

      Adding typespecs gives tools like Dialyzer more information when performing
      checks for type errors in function calls and definitions.

          @spec add(integer, integer) :: integer
          def add(a, b), do: a + b

      Functions with multiple arities need to have a spec defined for each arity:

          @spec foo(integer) :: boolean
          @spec foo(integer, integer) :: boolean
          def foo(a), do: a > 0
          def foo(a, b), do: a > b

      The check only considers whether the specification is present, it doesn't
      perform any actual type checking.

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)
    specs = Credo.Code.prewalk(source_file, &find_specs(&1, &2))

    Credo.Code.prewalk(source_file, &traverse(&1, &2, specs, issue_meta))
  end

  defp find_specs(
         {:spec, _, [{:when, _, [{:"::", _, [{name, _, args}, _]}, _]} | _]} = ast,
         specs
       ) do
    {ast, [{name, length(args)} | specs]}
  end

  defp find_specs({:spec, _, [{_, _, [{name, _, args} | _]}]} = ast, specs)
       when is_list(args) or is_nil(args) do
    args = with nil <- args, do: []
    {ast, [{name, length(args)} | specs]}
  end

  defp find_specs({:impl, _, [impl]} = ast, specs) when impl != false do
    {ast, [:impl | specs]}
  end

  defp find_specs({:def, meta, [{:when, _, def_ast} | _]}, [:impl | specs]) do
    find_specs({:def, meta, def_ast}, [:impl | specs])
  end

  defp find_specs({:def, _, [{name, _, nil}, _]} = ast, [:impl | specs]) do
    {ast, [{name, 0} | specs]}
  end

  defp find_specs({:def, _, [{name, _, args}, _]} = ast, [:impl | specs]) do
    {ast, [{name, length(args)} | specs]}
  end

  defp find_specs(ast, issues) do
    {ast, issues}
  end

  # TODO: consider for experimental check front-loader (ast)
  defp traverse(
         {:def, meta, [{:when, _, def_ast} | _]},
         issues,
         specs,
         issue_meta
       ) do
    traverse({:def, meta, def_ast}, issues, specs, issue_meta)
  end

  defp traverse(
         {:def, meta, [{name, _, args} | _]} = ast,
         issues,
         specs,
         issue_meta
       )
       when is_list(args) or is_nil(args) do
    args = with nil <- args, do: []

    if {name, length(args)} in specs do
      {ast, issues}
    else
      {ast, [issue_for(issue_meta, meta[:line], name) | issues]}
    end
  end

  defp traverse(ast, issues, _specs, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Functions should have a @spec type specification.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
