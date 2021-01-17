defmodule Credo.Check.Warning.WrongTestFileExtension do
  use Credo.Check,
    base_priority: :high,
    param_defaults: [included: ["test/**/*_test.ex"]],
    explanations: [
      check: """
      Invoking mix test from the command line will run the tests in each file
      matching the pattern `*_test.exs` found in the test directory of your project.

      (from the `ex_unit` docs)

      This check ensures that test files are not ending with `.ex` (which would cause them to be skipped).
      """
    ]

  @test_files_with_ex_ending_regex ~r/test\/.*\/.*_test.ex$/

  alias Credo.SourceFile

  @doc false
  def run(%SourceFile{filename: filename} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    if matches?(filename, @test_files_with_ex_ending_regex) do
      issue_meta
      |> issue_for()
      |> List.wrap()
    else
      []
    end
  end

  defp issue_for(issue_meta) do
    format_issue(
      issue_meta,
      message: "Test files should end with .exs"
    )
  end

  defp matches?(directory, path) when is_binary(path), do: String.starts_with?(directory, path)
  defp matches?(directory, %Regex{} = regex), do: Regex.match?(regex, directory)
end
