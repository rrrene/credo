defmodule Credo.Check.Readability.ParenthesesOnZeroArityDefs do
  use Credo.Check,
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

  alias Credo.Check.Params

  @def_ops [:def, :defp, :defmacro, :defmacrop]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    parens? = Params.get(params, :parens, __MODULE__)
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, parens?))
  end

  # TODO: consider for experimental check front-loader (ast)
  for op <- @def_ops do
    # catch variables named e.g. `defp`
    defp traverse({unquote(op), _, nil} = ast, issues, _issue_meta, _parens?) do
      {ast, issues}
    end

    defp traverse({unquote(op), _, body} = ast, issues, issue_meta, parens?) do
      function_head = Enum.at(body, 0)

      {ast, issues_for_definition(function_head, issues, issue_meta, parens?)}
    end
  end

  defp traverse(ast, issues, _issue_meta, _parens?) do
    {ast, issues}
  end

  # skip the false positive for a metaprogrammed definition
  defp issues_for_definition({{:unquote, _, _}, _, _}, issues, _, _parens?) do
    issues
  end

  defp issues_for_definition({_, _, args}, issues, _, _parens?) when length(args) > 0 do
    issues
  end

  defp issues_for_definition({name, meta, _}, issues, issue_meta, enforce_parens?) do
    line_no = meta[:line]
    text = remaining_line_after(issue_meta, line_no, name)
    parens? = String.match?(text, ~r/^\((\w*)\)(.)*/)

    cond do
      parens? and not enforce_parens? ->
        issues ++ [issue_for(issue_meta, line_no, :present)]

      not parens? and enforce_parens? ->
        issues ++ [issue_for(issue_meta, line_no, :missing)]

      true ->
        issues
    end
  end

  defp remaining_line_after(issue_meta, line_no, text) do
    source_file = IssueMeta.source_file(issue_meta)
    line = SourceFile.line_at(source_file, line_no)
    name_size = text |> to_string |> String.length()
    skip = (SourceFile.column(source_file, line_no, text) || -1) + name_size - 1

    String.slice(line, skip..-1)
  end

  defp issue_for(issue_meta, line_no, kind) do
    message =
      case kind do
        :present ->
          "Do not use parentheses when defining a function which has no arguments."

        :missing ->
          "Use parentheses () when defining a function which has no arguments."
      end

    format_issue(issue_meta, message: message, line_no: line_no)
  end
end
