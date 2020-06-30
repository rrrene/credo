defmodule Credo.Check.Refactor.DoubleBooleanNegation do
  use Credo.Check,
    base_priority: :low,
    tags: [:controversial],
    explanations: [
      check: """
      Having double negations in your code can obscure the parameter's original value.

          # NOT preferred

          !!var

      This will return `false` for `false` and `nil`, and `true` for anything else.

      At first this seems like an extra clever shorthand to cast anything truthy to
      `true` and anything non-truthy to `false`. But in most scenarios you want to
      be explicit about your input parameters (because it is easier to reason about
      edge-cases, code-paths and tests).
      Also: `nil` and `false` do mean two different things.

      A scenario where you want this kind of flexibility, however, is parsing
      external data, e.g. a third party JSON-API where a value is sometimes `null`
      and sometimes `false` and you want to normalize that before handing it down
      in your program.

      In these case, you would be better off making the cast explicit by introducing
      a helper function:

          # preferred

          defp present?(nil), do: false
          defp present?(false), do: false
          defp present?(_), do: true

      This makes your code more explicit than relying on the implications of `!!`.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # Checking for `!!`
  defp traverse({:!, meta, [{:!, _, ast}]}, issues, issue_meta) do
    issue =
      format_issue(
        issue_meta,
        message: "Double boolean negation found.",
        trigger: "!!",
        line_no: meta[:line]
      )

    {ast, [issue | issues]}
  end

  # Checking for `not not`
  defp traverse({:not, meta, [{:not, _, ast}]}, issues, issue_meta) do
    issue =
      format_issue(
        issue_meta,
        message: "Double boolean negation found.",
        trigger: "not not",
        line_no: meta[:line]
      )

    {ast, [issue | issues]}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end
end
