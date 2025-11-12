defmodule Credo.Check.Refactor.DoubleBooleanNegation do
  use Credo.Check,
    id: "EX4007",
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

  @negation_operators [:!, :not]
  defguard is_doube_negation(a, b) when a in @negation_operators and b in @negation_operators

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  defp walk({a, meta, [{b, _, ast}]}, ctx) when is_doube_negation(a, b) do
    {ast, put_issue(ctx, issue_for(ctx, meta, format_trigger(a, b)))}
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp format_trigger(:!, :!), do: "!!"
  defp format_trigger(a, b), do: Enum.join([a, b], " ")

  defp issue_for(ctx, meta, trigger) do
    format_issue(
      ctx,
      message: "Double boolean negation found.",
      trigger: trigger,
      line_no: meta[:line]
    )
  end
end
