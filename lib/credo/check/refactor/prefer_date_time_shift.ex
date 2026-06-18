defmodule Credo.Check.Refactor.PreferDateTimeShift do
  use Credo.Check,
    id: "EX4034",
    base_priority: :low,
    explanations: [
      check: """
      `Date.shift/2`, `DateTime.shift/2`, `NaiveDateTime.shift/2`, and
      `Time.shift/2` are preferred over their `add/2` counterparts.
       I.e. https://hexdocs.pm/elixir/NaiveDateTime.html#add/3 says:

       > Prefer `shift/2` over `add/3`, as it offers a more ergonomic API.
       >
       > `add/3` provides a lower-level API which only supports fixed units such as :hour
       > and :second, but not :month (as the exact length of a month depends on the
       > current month). `add/3` always considers the unit to be computed according
       > to the `Calendar.ISO`.

      For example, the code here ...

          Date.add(date, 1)
          DateTime.add(dt, 1, :hour)
          DateTime.add(dt, 10) # defaults to :second
          NaiveDateTime.add(dt, 7, :day)
          Time.add(time, 30, :minute)

      ... can be refactored to look like this:

          Date.shift(date, day: 1)
          DateTime.shift(dt, hour: 1)
          DateTime.shift(dt, second: 10)
          NaiveDateTime.shift(dt, day: 7)
          Time.shift(time, minute: 30)
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
  defp walk(
         {{:., meta, [{:__aliases__, _, [mod]}, :add]}, _, _args} = ast,
         ctx
       )
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
