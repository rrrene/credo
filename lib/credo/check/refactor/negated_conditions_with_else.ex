defmodule Credo.Check.Refactor.NegatedConditionsWithElse do
  @moduledoc """
  An `if` block with a negated condition should not contain an else block.

  So while this is fine:

      if !allowed? do
        raise "Not allowed!"
      end

  The code in this example ...

      if !allowed? do
        raise "Not allowed!"
      else
        proceed_as_planned
      end

  ... should be refactored to look like this:

      if allowed? do
        proceed_as_planned
      else
        raise "Not allowed!"
      end

  The reason for this is not a technical but a human one. It is easier to wrap
  your head around a positive condition and then thinking "and else we do ...".

  In the above example raising the error in case something is not allowed
  might seem so important to put it first. But when you revisit this code a
  while later or have to introduce a colleague to it, you might be surprised
  how much clearer things get when the "happy path" comes first.
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :high

  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.traverse(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({:if, meta, arguments} = ast, issues, issue_meta) do
    if negated_condition?(arguments) && CodeHelper.else_block?(ast) do
      new_issue =
        issue_for(issue_meta, meta[:line], "!")

      {ast, issues ++ [new_issue]}
    else
      {ast, issues}
    end
  end
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp negated_condition?(arguments) when is_list(arguments) do
    arguments |> List.first |> negated_condition?()
  end
  defp negated_condition?({:!, _meta, _arguments}) do
    true
  end
  # parentheses around the condition wrap it in a __block__
  defp negated_condition?({:__block__, _meta, arguments}) do
    arguments |> negated_condition?()
  end
  defp negated_condition?(_) do
    false
  end


  defp issue_for(issue_meta, line_no, trigger) do
    format_issue issue_meta,
      message: "If/else blocks should not have a negated condition in `if`.",
      trigger: trigger,
      line_no: line_no
  end
end
