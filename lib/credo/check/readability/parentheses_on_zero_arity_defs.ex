defmodule Credo.Check.Readability.ParenthesesOnZeroArityDefs do
  use Credo.Check,
    id: "EX3014",
    base_priority: :low,
    param_defaults: [parens: false],
    explanations: [
      check: """
      Either use parentheses or not when defining a function with no arguments.

      By default, this check enforces no parentheses, so zero-arity function
      and macro definitions should look like this:

          def summer? do
            # ...
          end

      If the `:parens` param is set to `true` for this check, then the check
      enforces zero-arity function and macro definitions to have parens:

          def summer?() do
            # ...
          end

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  @def_ops [:def, :defp, :defmacro, :defmacrop]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  for op <- @def_ops do
    # catch variables named e.g. `defp`
    defp walk({unquote(op), _, nil} = ast, ctx) do
      {ast, ctx}
    end

    defp walk({unquote(op), _, [{{:unquote, _, _}, _, _} | _]} = ast, ctx) do
      {ast, ctx}
    end

    defp walk({unquote(op), _, [{_, _, [_at_least_one_arg | _rest]} | _]} = ast, ctx) do
      {ast, ctx}
    end

    defp walk({unquote(op), _, [{name, meta, _} | _]} = ast, ctx) do
      line_no = meta[:line]
      text = remaining_line_after(ctx, line_no, name)
      enforce_parens? = ctx.params.parens
      parens? = String.match?(text, ~r/^\((\w*)\)(.)*/)

      cond do
        parens? and not enforce_parens? ->
          {ast, put_issue(ctx, issue_for(ctx, name, line_no, :present))}

        not parens? and enforce_parens? ->
          {ast, put_issue(ctx, issue_for(ctx, name, line_no, :missing))}

        true ->
          {ast, ctx}
      end
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp remaining_line_after(ctx, line_no, text) do
    source_file = IssueMeta.source_file(ctx)
    line = SourceFile.line_at(source_file, line_no)
    name_size = text |> to_string |> String.length()
    skip = (SourceFile.column(source_file, line_no, text) || -1) + name_size - 1

    String.slice(line, skip..-1//1)
  end

  defp issue_for(ctx, name, line_no, kind) do
    message =
      case kind do
        :present ->
          "Do not use parentheses when defining a function which has no arguments."

        :missing ->
          "Use parentheses when defining a function which has no arguments."
      end

    format_issue(ctx, message: message, line_no: line_no, trigger: name)
  end
end
