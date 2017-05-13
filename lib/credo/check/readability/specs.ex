defmodule Credo.Check.Readability.Specs do
  @moduledoc """
  Functions, callbacks and macros need typespecs.

  Adding typespecs allows tools like dialyzer to perform success typing on
  functions. Without a spec functions and macros are ignored by the type
  checker.

      @spec add(integer, integer) :: integer
      def add(a, b), do: a + b

  Functions with multiple arities need to have a spec defined for each arity:

      @spec foo(integer) :: boolean
      @spec foo(integer, integer) :: boolean
      def foo(a), do: a > 0
      def foo(a, b), do: a > b

  The check only considers whether the specification is present, it doesn't
  perform any actual type checking.
  """

  @explanation [check: @moduledoc]

  use Credo.Check

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    specs = Credo.Code.prewalk(source_file, &find_specs(&1, &2))

    Credo.Code.prewalk(source_file, &traverse(&1, &2, specs, issue_meta))
  end

  defp find_specs({:spec, _, [{_, _, [{name, _, args} | _]}]} = ast, specs) when is_list(args) do
    {ast, [{name, length(args)} | specs]}
  end
  defp find_specs(ast, issues) do
    {ast, issues}
  end

  defp traverse({:def, meta, [{:when, _, def_ast} | _]}, issues, specs, issue_meta) do
    traverse({:def, meta, def_ast}, issues, specs, issue_meta)
  end
  defp traverse({:def, meta, [{name, _, args} | _]} = ast, issues, specs, issue_meta) when is_list(args) do
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
    format_issue issue_meta,
      message: "Functions should have a @spec type specification.",
      trigger: trigger,
      line_no: line_no
  end
end
