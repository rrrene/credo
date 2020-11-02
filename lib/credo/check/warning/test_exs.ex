defmodule Credo.Check.Warning.TestExs do
  use Credo.Check,
    base_priority: :high,
    param_defaults: [excluded_paths: []],
    explanations: [
      check: """
      Invoking mix test from the command line will run the tests in each file
      matching the pattern `*_test.exs` found in the test directory of your project.

      (from the `ex_unit` docs)

      This check ensures that test files are not ending with `.ex` (which would cause them to be skipped).

      """,
      params: [
        excluded_paths: "List of paths or regex to exclude from this check"
      ]
    ]

  @test_files_with_ex_ending_regex ~r/test\/.*\/.*_test.ex$/

  alias Credo.SourceFile

  @doc false
  def run(%SourceFile{filename: filename} = source_file, params \\ []) do
    excluded_paths = Params.get(params, :excluded_paths, __MODULE__)
    ignored = ignore_path?(filename, excluded_paths)

    process_source_file(source_file, params, ignored)
  end

  defp process_source_file(_source_file, _params, true = _ignored), do: []

  defp process_source_file(
         %SourceFile{filename: filename} = source_file,
         params,
         false = _ignored
       ) do
    issue_meta = IssueMeta.for(source_file, params)

    cond do
      matches?(filename, @test_files_with_ex_ending_regex) ->
        issue_for(issue_meta)
        |> List.wrap()

      :else ->
        []
    end
  end

  defp issue_for(issue_meta) do
    format_issue(
      issue_meta,
      message: "Test files should end with .exs"
    )
  end

  # Check if analyzed module path is within ignored paths
  defp ignore_path?(filename, excluded_paths) do
    directory = Path.dirname(filename)

    Enum.any?(excluded_paths, &matches?(directory, &1))
  end

  defp matches?(directory, %Regex{} = regex), do: Regex.match?(regex, directory)
  defp matches?(directory, path) when is_binary(path), do: String.starts_with?(directory, path)
end
