defmodule Credo.Check.Warning.WrongTestFileExtension do
  use Credo.Check,
    id: "EX5025",
    base_priority: :high,
    param_defaults: [
      files: %{included: ["test/**/*_test.ex", "apps/**/test/**/*_test.ex"]}
    ],
    explanations: [
      check: """
      Invoking mix test from the command line will run the tests in each file
      matching the pattern `*_test.exs` found in the test directory of your project.

      (from the `ex_unit` docs)

      This check ensures that test files are not ending with `_test.ex` (which would cause them to be skipped).
      """
    ]

  alias Credo.SourceFile

  @doc false
  def run(%SourceFile{} = source_file, params \\ []) do
    source_file
    |> Context.build(params, __MODULE__)
    |> issue_for()
    |> List.wrap()
  end

  defp issue_for(ctx) do
    format_issue(
      ctx,
      message: "Test files should end with `_test.exs`.",
      line_no: 1,
      trigger: Issue.no_trigger()
    )
  end
end
