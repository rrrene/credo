defmodule Credo.Check.Readability.AlwaysMatchingCondClause do
  @moduledoc false

  @checkdoc """
  If you provide an "always true" clause in `cond`, it should be the literal value `true`.

  Correct:
      cond do
        x > 5 -> 10
        x < 5 -> 0
        true -> 5
      end
  Incorrect
      cond do
        x > 5 -> 10
        x < 5 -> 0
        :other -> 5
      end
  Consistency in this regard helps developers quickly identify fall through cases and not
  mistake the "always true" clause for relevant code.
  """
  @explanation [check: @checkdoc]

  alias Credo.Code.Block

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    allowed_values = params[:allowed_values] || [true, :else]

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta, allowed_values))
  end

  defp traverse({:cond, meta, arguments} = ast, issues, issue_meta, allowed_values) do
    last_clause =
      arguments
      |> Block.do_block_for!()
      |> List.wrap()
      |> List.last()

    case last_clause do
      {:->, _, [[value] | _]} when is_tuple(value) ->
        {ast, issues}

      {:->, _, [[value] | _]} ->
        if value in allowed_values do
          {ast, issues}
        else
          {ast, [issue_for(issue_meta, meta[:line], allowed_values) | issues]}
        end

      _ ->
        {ast, [issue_for(issue_meta, meta[:line], allowed_values) | issues]}
    end
  end

  defp traverse(ast, issues, _, _) do
    {ast, issues}
  end

  defp issue_for(issue_meta, line_no, values) do
    values_string =
      case values do
        [value] -> "`#{inspect(value)}`"
        values -> "one of `#{inspect(values)}`"
      end

    format_issue(
      issue_meta,
      message: "If you provide an 'always true' clause to `cond`, it should be #{values_string}.",
      trigger: "always_matching_cond_clause_true",
      line_no: line_no
    )
  end
end
