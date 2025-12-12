defmodule Credo.Check.Refactor.PassAsyncInTestCases do
  use Credo.Check,
    id: "EX4031",
    base_priority: :normal,
    param_defaults: [
      files: %{included: ["test/**/*_test.exs", "apps/**/test/**/*_test.exs"]}
    ],
    explanations: [
      check: """
      Test modules marked `async: true` are run concurrently, speeding up the
      test suite and improving productivity. This should always be done when
      possible.

      Leaving off the `async:` option silently defaults to `false`, which may make
      a test suite slower for no real reason.

      Test modules which cannot be run concurrently should be explicitly marked
      `async: false`, ideally with a comment explaining why.
      """
    ]

  def run(source_file, params \\ []) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # `use` with options
  defp walk({:use, meta, [{_, _meta, module_namespace}, [_ | _] = options]} = ast, ctx) do
    module_name = Credo.Code.Name.last(module_namespace)

    if String.ends_with?(module_name, "Case") and !Keyword.has_key?(options, :async) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  # `use` without options
  defp walk({:use, meta, [{_op, _meta, module_namespace}]} = ast, ctx) do
    module_name = Credo.Code.Name.last(module_namespace)

    if String.ends_with?(module_name, "Case") do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp issue_for(ctx, meta) do
    format_issue(
      ctx,
      message: "Pass an `:async` boolean option to `use` a test case module.",
      trigger: "use",
      line_no: meta[:line]
    )
  end
end
