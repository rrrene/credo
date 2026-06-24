defmodule Credo.Check.Refactor.PreferDateTimeShift do
  use Credo.Check,
    id: "EX4034",
    base_priority: :low,
    elixir_version: ">= 1.17.0",
    explanations: [
      check: """
      For `Date`, `DateTime`, `NaiveDateTime` and `Time` prefer `shift/2`
      over `add/2`, as it provides a more ergonomic API.

      This should be refactored:

          Date.add(date, 1)
          DateTime.add(dt, 1, :hour)
          NaiveDateTime.add(dt, 7, :day)
          Time.add(time, 30, :minute)

      to look like this:

          Date.shift(date, day: 1)
          DateTime.shift(dt, hour: 1)
          NaiveDateTime.shift(dt, day: 7)
          Time.shift(time, minute: 30)

      See https://hexdocs.pm/elixir/NaiveDateTime.html#add/3
      """
    ]

  @doc false
  def run(source_file, params \\ []) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # Both `Mod.add(dt, ...)` and `dt |> Mod.add(...)` desugar to the same
  # `{:., _, [Mod, :add]}` AST node, so this single clause covers all forms
  # and arities for all four calendar modules.
  defp walk({{:., meta, [{:__aliases__, _, [mod]}, :add]}, _, _args} = ast, ctx)
       when mod in [:Date, :DateTime, :NaiveDateTime, :Time] do
    {ast, put_issue(ctx, issue_for(ctx, meta, mod))}
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp issue_for(ctx, meta, mod_name) do
    format_issue(ctx,
      message: "Prefer `#{mod_name}.shift/2` over `#{mod_name}.add`.",
      trigger: "#{mod_name}.add",
      line_no: meta[:line]
    )
  end
end
