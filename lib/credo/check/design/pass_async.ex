defmodule Credo.Check.Design.PassAsync do
  @moduledoc """
  Check that we pass an `async` option when we `use` test case modules.
  """

  use Credo.Check,
    base_priority: :normal,
    category: :consistency,
    param_defaults: [],
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
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  # `use` with options
  defp traverse({:use, _, [{_, meta, module_namespace}, options]} = ast, issues, issue_meta) do
    module_name = module_name_from(module_namespace)

    if String.ends_with?(module_name, "Case") and !Keyword.has_key?(options, :async) do
      {ast, issues ++ [issue_for(ast, meta[:line], issue_meta)]}
    else
      {ast, issues}
    end
  end

  # `use` without options
  defp traverse({:use, _, [{_, meta, module_namespace}]} = ast, issues, issue_meta) do
    module_name = module_name_from(module_namespace)

    if String.ends_with?(module_name, "Case") do
      {ast, issues ++ [issue_for(ast, meta[:line], issue_meta)]}
    else
      {ast, issues}
    end
  end

  # Ignore all other AST nodes
  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(ast, line_no, issue_meta) do
    format_issue(
      issue_meta,
      message: "Pass an `:async` boolean option to `use` a test case module",
      trigger: to_code(ast),
      line_no: line_no
    )
  end

  defp module_name_from(module_namespace) do
    module_namespace
    |> List.last()
    |> to_string()
  end

  defp to_code(ast) do
    ast
    |> Code.quoted_to_algebra()
    |> Inspect.Algebra.format(:infinity)
    |> IO.iodata_to_binary()
  end
end
