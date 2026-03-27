defmodule Credo.Check.Warning.UnusedFunctionParameterPattern do
  @moduledoc false

  use Credo.Check,
    id: "EX5031",
    base_priority: :normal,
    category: :warning,
    explanations: [
      check: """
      Pattern matches in function parameters that are immediately ignored should be avoided.

      For example:

          def foo(%{} = _ignored) do
            # ...
          end

      In this case, the pattern match `= _ignored` is unnecessary because the variable cannot be used. It's better to remove the binding.

      Instead, consider:

          def foo(%{}) do
            # ...
          end

      If you want to use the name as a form of documentation, try a type specification:

          @spec foo(name :: map()) :: term()
          def foo(%{}) do
            # ...
          end

      or:

          @spec foo(name) :: term() when name: map()
          def foo(%{}) do
            # ...
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

  @def_ops [:def, :defp, :defmacro]

  defp walk({def_op, _meta, arguments} = ast, ctx) when def_op in @def_ops do
    case arguments do
      [{:when, _when_meta, [{_fun_name, _fun_meta, args} | _guards]} | _] when is_list(args) ->
        {ast, find_unused_patterns(args, ctx)}

      [{_fun_name, _fun_meta, args} | _] when is_list(args) ->
        {ast, find_unused_patterns(args, ctx)}

      _ ->
        {ast, ctx}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp find_unused_patterns(args, ctx) do
    Credo.Code.prewalk(args, &find_matches/2, ctx)
  end

  defp find_matches({:=, meta, [lhs, rhs]} = ast, ctx) do
    ctx =
      case {lhs, rhs} do
        {_lhs, {name, _name_meta, nil}} when is_atom(name) ->
          check_unused(name, meta, ctx)

        {{name, _name_meta, nil}, _rhs} when is_atom(name) ->
          check_unused(name, meta, ctx)

        _ ->
          ctx
      end

    {ast, ctx}
  end

  defp find_matches(ast, ctx) do
    {ast, ctx}
  end

  defp check_unused(name, meta, ctx) do
    string_name = to_string(name)

    if String.starts_with?(string_name, "_") do
      put_issue(ctx, issue_for(meta, ctx))
    else
      ctx
    end
  end

  defp issue_for(meta, ctx) do
    format_issue(ctx,
      message: "Function parameter has a pattern match but is immediately ignored.",
      trigger: "=",
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
