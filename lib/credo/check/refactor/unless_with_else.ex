defmodule Credo.Check.Refactor.UnlessWithElse do
  @moduledoc """
  An `unless` block should not contain an else block.

  So while this is fine:

      unless allowed? do
        raise "Not allowed!"
      end

  This should be refactored:

      unless allowed? do
        raise "Not allowed!"
      else
        proceed_as_planned()
      end

  to look like this:

      if allowed? do
        proceed_as_planned()
      else
        raise "Not allowed!"
      end

  The reason for this is not a technical but a human one. The `else` in this
  case will be executed when the condition is met, which is the opposite of
  what the wording seems to apply.
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:@, _, [{:unless, _, _}]}, issues, _issue_meta) do
    {nil, issues}
  end
  defp traverse({:unless, meta, _arguments} = ast, issues, issue_meta) do
    new_issue =
      issue_for_else_block(CodeHelper.else_block_for!(ast), meta, issue_meta)

    {ast, issues ++ List.wrap(new_issue)}
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for_else_block(nil, _meta, _issue_meta), do: nil
  defp issue_for_else_block(_else_block, meta, issue_meta) do
    issue_for(issue_meta, meta[:line], "unless")
  end


  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "Unless conditions should not have an `else` block.",
      trigger: trigger,
      line_no: line_no
  end
end
