defmodule Credo.Check.Readability.FunctionNames do
  @moduledoc """
  Function and macro names are always written in snake_case in Elixir.

      # snake_case:

      def handle_incoming_message(message) do
      end

      # not snake_case

      def handleIncomingMessage(message) do
      end

  Like all `Readability` issues, this one is not a technical concern.
  But you can improve the odds of others reading and liking your code by making
  it easier to follow.
  """

  @explanation [check: @moduledoc]
  @def_ops Application.get_env(:credo, :def_ops)

  alias Credo.Code.Name

  use Credo.Check, base_priority: :high

  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.traverse(source_file, &traverse(&1, &2, issue_meta))
  end

  for op <- @def_ops do
    defp traverse({unquote(op), _meta, arguments} = ast, issues, issue_meta) do
      {ast, issues_for_definition(arguments, issues, issue_meta)}
    end
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issues_for_definition(body, issues, issue_meta) do
    case Enum.at(body, 0) do
      {name, meta, nil} ->
        issues_for_name(name, meta, issues, issue_meta)
      _ ->
        issues
    end
  end

  def issues_for_name(name, meta, issues, issue_meta) do
    if name |> to_string |> Name.snake_case? do
      issues
    else
      [issue_for(meta[:line], name, issue_meta) | issues]
    end
  end

  defp issue_for(line_no, trigger, issue_meta) do
    format_issue issue_meta,
      message: "Function/macro names should be written in snake_case.",
      trigger: trigger,
      line_no: line_no
  end
end
