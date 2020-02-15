defmodule Credo.Check.Readability.AliasAs do
  use Credo.Check,
    base_priority: :low,
    explanations: [
      check: """
      Aliases which are not completely renamed using the `:as` option are easier to follow.

          # preferred

          alias MyApp.Module1

          # NOT preferred

          alias MyApp.Module1, as: M1

      Like all `Readability` issues, this one is not a technical concern.
      But you can improve the odds of others reading and liking your code by making
      it easier to follow.
      """
    ]

  alias Credo.Code

  @doc false
  def run(source_file, params \\ []) do
    source_file
    |> Code.prewalk(&traverse(&1, &2, IssueMeta.for(source_file, params)))
    |> Enum.reverse()
  end

  defp traverse(ast, issues, issue_meta), do: {ast, add_issue(issues, issue(ast, issue_meta))}

  defp add_issue(issues, nil), do: issues
  defp add_issue(issues, issue), do: [issue | issues]

  defp issue({:alias, _, [{:__MODULE__, _, nil}, [as: {_, meta, _}]]}, issue_meta),
    do: issue_for(issue_meta, meta[:line], inspect(:__MODULE__))

  defp issue({:alias, _, [{_, _, original}, [as: {_, meta, _}]]}, issue_meta),
    do: issue_for(issue_meta, meta[:line], inspect(Module.concat(original)))

  defp issue(_ast, _issue_meta), do: nil

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "Avoid using the :as option with alias.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
