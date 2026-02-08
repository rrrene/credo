defmodule Credo.Check.Warning.WrongTestFilename do
  use Credo.Check,
    id: "EX5030",
    base_priority: :high,
    category: :warning,
    param_defaults: [
      files: %{
        included: ["test/"],
        excluded: ["test/**/*_test.exs", "apps/**/test/**/*_test.exs"]
      }
    ],
    explanations: [
      check: """
      Invoking mix test from the command line will run the tests in each file
      matching the pattern `*_test.exs` found in the test directory of your project.

      (from the `ex_unit` docs)

      This test ensures that files containing `use ExUnit.Case` and related cases are only
      used in files ending with `_test.exs`.

      If you have a file named differently (say, `test_my_module.exs`), you will be able to
      run `mix test test/test_my_module.exs` and see the tests run. This can mislead you
      into believing that subsequently running the full test suite (`mix test`) will also
      test your file.
      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{filename: filename} = source_file, params \\ []) do
    if String.ends_with?(filename, "_test.exs") do
      []
    else
      ctx = Context.build(source_file, params, __MODULE__)
      result = Credo.Code.prewalk(source_file, &walk/2, ctx)
      result.issues
    end
  end

  defp walk({:quote, _, [_ | _]}, ctx), do: {nil, ctx}

  defp walk({:use, meta, [{:__aliases__, _, module_parts} | _]} = ast, ctx) do
    module_name = Credo.Code.Name.full(module_parts)

    if String.ends_with?(module_name, "Case") do
      {ast, put_issue(ctx, issue_for(module_name, ctx, meta))}
    else
      {ast, ctx}
    end
  end

  defp walk(ast, ctx), do: {ast, ctx}

  defp issue_for(module_name, ctx, meta) do
    format_issue(
      ctx,
      message: "Test files that `use #{module_name}` should end with `_test.exs`.",
      trigger: module_name,
      line_no: meta[:line]
    )
  end
end
