defmodule Credo.Check.Refactor.PassAsyncInTestCases do
  use Credo.Check,
    id: "EX4031",
    base_priority: :normal,
    param_defaults: [
      files: %{included: ["test/**/*_test.exs", "apps/**/test/**/*_test.exs"]},
      force_comment_on_explicit_false: false
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
      """,
      params: [
        force_comment_on_explicit_false: "Force adding a comment when `async: false` is used."
      ]
    ]

  def run(source_file, params \\ []) do
    ctx = Context.build(source_file, params, __MODULE__)
    result = Credo.Code.prewalk(source_file, &walk/2, ctx)
    result.issues
  end

  # `use` with options
  defp walk({:use, meta, [{_, _meta, module_namespace}, [_ | _] = options]} = ast, ctx) do
    module_name = Credo.Code.Name.last(module_namespace)

    if String.ends_with?(module_name, "Case") do
      case Keyword.fetch(options, :async) do
        :error ->
          {ast, put_issue(ctx, issue_for(ctx, meta))}

        {:ok, true} ->
          {ast, ctx}

        {:ok, false} ->
          handle_explicit_async_false(ast, ctx)
      end
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

  defp handle_explicit_async_false({:use, meta, _} = ast, ctx) do
    if ctx.params.force_comment_on_explicit_false and not has_comment?(ctx, meta[:line]) do
      {ast, put_issue(ctx, issue_for(ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp has_comment?(ctx, line) do
    found_line =
      ctx.source_file
      |> Credo.Code.to_lines()
      |> Enum.find(fn {line_no, _line} -> line_no == line - 1 end)

    case found_line do
      {_line_no, line_content} -> line_content =~ ~r/^\s*#.*$/
      nil -> false
    end
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
