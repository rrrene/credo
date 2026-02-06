defmodule Credo.Check.Warning.WrongTestFileName do
  @moduledoc """
  Ensures that `use ExUnit.Case` and related test cases are only used in test files.
  """
  use Credo.Check,
    base_priority: :high,
    category: :warning,
    param_defaults: [
      files: %{excluded: ["test/**/*_test.exs", "apps/**/test/**/*_test.exs"]}
    ],
    explanations: [
      check: """
      Ensures that `use ExUnit.Case` and related test cases are only used in files ending with `_test.exs`.

      ExUnit.Case is designed for test modules and provides test-specific functionality
      like database sandboxing and test macros. Using it in non-test files is likely a
      mistake in the file name and will cause the tests in that module not to be run.

      ExUnit's docs say:

      > Invoking mix test from the command line will run the tests in each file
      > matching the pattern `*_test.exs` found in the test directory of your project.

      If you have a file named differently (say, `test_my_module.exs`), you will be able to
      run `mix test test/test_my_module.exs` and see the tests run. This can mislead you
      into believing that subsequently running the full test suite (`mix test`) will also
      test your file.
      """
    ]

  @doc false
  @impl Credo.Check
  def run(%SourceFile{filename: filename} = source_file, params \\ []) do
    # Only check non-test files, excluding custom case modules which may invoke
    # `use ExUnit.Case` themselves.
    if String.ends_with?(filename, ["_test.exs", "_case.ex"]) do
      []
    else
      issue_meta = IssueMeta.for(source_file, params)
      Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
    end
  end

  defp traverse({:use, meta, [{:__aliases__, _, module_parts} | _]} = node, issues, issue_meta) do
    case parse_test_case_module(module_parts) do
      {:ok, module_name} -> {node, issues ++ [create_issue(module_name, issue_meta, meta[:line])]}
      {:error, :not_a_test_case_module} -> {node, issues}
    end
  end

  defp traverse(node, issues, _issue_meta), do: {node, issues}

  defp create_issue(module_name, issue_meta, line_no) do
    format_issue(
      issue_meta,
      message: "Test files that `use #{module_name}` should end with `_test.exs`.",
      trigger: "use #{module_name}",
      line_no: line_no
    )
  end

  defp parse_test_case_module(module_parts) do
    last_part = module_parts |> List.last() |> to_string()

    if String.ends_with?(last_part, "Case") do
      # Use inspect(), not to_string(), to get MyApp.MyModule instead of Elixir.MyApp.MyModule
      {:ok, module_parts |> Module.concat() |> inspect()}
    else
      {:error, :not_a_test_case_module}
    end
  end
end
