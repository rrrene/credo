defmodule Credo.Check.Readability.UnusedFunctionParameterPattern do
  @moduledoc false

  use Credo.Check,
    id: "EX5031",
    base_priority: :normal,
    explanations: [
      check: """
      Pattern matches in function parameters that are immediately ignored should be avoided.

      For example, the pattern match `= _user_params` is unnecessary because the variable cannot be used.

          def valid?(%{} = _user_params) do
            # ...
          end

      If you want to use the name as a form of documentation, try a type specification:

          @spec valid?(user_params :: map()) :: term()
          def valid?(%{}) do
            # ...
          end

      or:

          @spec valid?(user_params) :: term() when user_params: map()
          def valid?(%{}) do
            # ...
          end

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  @def_ops [:def, :defp, :defmacro]

  defp walk({def_op, _meta, [{:when, _when_meta, [{_fun_name, _fun_meta, arguments} | _guards]} | _]} = ast, ctx)
       when def_op in @def_ops and is_list(arguments) do
    {ast, find_unused_patterns(arguments, ctx)}
  end

  defp walk({def_op, _meta, [{_fun_name, _fun_meta, arguments} | _]} = ast, ctx)
       when def_op in @def_ops and is_list(arguments) do
    {ast, find_unused_patterns(arguments, ctx)}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp find_unused_patterns(args, ctx) do
    Credo.Code.prewalk(args, &find_matches/2, ctx)
  end

  defp find_matches({:=, _meta, [{name, meta, nil}, _rhs]} = ast, ctx) when is_atom(name) do
    {ast, put_issue(ctx, issue_if_unused_parameter(to_string(name), meta, ctx))}
  end

  defp find_matches({:=, _meta, [_lhs, {name, meta, nil}]} = ast, ctx) when is_atom(name) do
    {ast, put_issue(ctx, issue_if_unused_parameter(to_string(name), meta, ctx))}
  end

  defp find_matches(ast, ctx) do
    {ast, ctx}
  end

  defp issue_if_unused_parameter("_" <> _ = name, meta, ctx) do
    issue_for(name, meta, ctx)
  end

  defp issue_if_unused_parameter(_name, _meta, _ctx) do
    nil
  end

  defp issue_for(name, meta, ctx) do
    format_issue(ctx,
      message: "Function parameter has a pattern match but is immediately ignored.",
      trigger: name,
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
