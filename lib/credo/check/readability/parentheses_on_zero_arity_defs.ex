defmodule Credo.Check.Readability.ParenthesesOnZeroArityDefs do
  @moduledoc """
  Do not use parentheses when defining a function which has no arguments.

  The code in this example ...

      def summer?() do
        # ...
      end

  ... should be refactored to look like this:

      def summer? do
        # ...
      end

  Like all `Readability` issues, this one is not a technical concern.
  But you can improve the odds of others reading and liking your code by making
  it easier to follow.
  """

  @explanation [check: @moduledoc]
  @def_ops [:def, :defp, :defmacro, :defmacrop]

  use Credo.Check, base_priority: :low

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  for op <- @def_ops do
    # catch variables named e.g. `defp`
    defp traverse({unquote(op), _, body} = ast, issues, issue_meta) do
      function_head = Enum.at(body, 0)
      {ast, issues_for_definition(function_head, issues, issue_meta)}
    end
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  # skip the false positive for a metaprogrammed definition
  defp issues_for_definition({{:unquote, _, _}, _, _}, issues, _) do
    issues
  end
  defp issues_for_definition({_, _, args}, issues, _) when length(args) > 0 do
    issues
  end
  defp issues_for_definition({name, meta, _}, issues, issue_meta) do
    line_no = meta[:line]
    text = remaining_line_after(issue_meta, line_no, name)

    if String.match?(text, ~r/^\((\w*)\)(.)*/) do
      issues ++ [issue_for(issue_meta, line_no)]
    else
      issues
    end
  end

  defp remaining_line_after(issue_meta, line_no, text) do
    source_file = IssueMeta.source_file(issue_meta)
    line = SourceFile.line_at(source_file, line_no)
    name_size = text |> to_string |> String.length
    skip = (SourceFile.column(source_file, line_no, text) || -1) + name_size - 1

    String.slice(line, skip..-1)
  end

  defp issue_for(issue_meta, line_no) do
    format_issue issue_meta,
      message: "Do not use parentheses when defining a function which has no arguments.",
      line_no: line_no
  end
end
