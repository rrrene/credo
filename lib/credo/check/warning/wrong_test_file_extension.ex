defmodule Credo.Check.Warning.WrongTestFileExtension do
  use Credo.Check,
    id: "EX5025",
    base_priority: :high,
    param_defaults: [excluded_paths: ["test/support", "test/test_helper.exs"]],
    explanations: [
      check: """
      This check ensures that all test files end in `_test.exs`.

      ### Background

      Running `mix test` will only execute the test files that match the pattern `*_test.exs` found
      in the in the `test` directory of your project.
      """,
      params: [
        excluded_paths: "List of paths or regex to exclude from this check"
      ]
    ]

  alias Credo.SourceFile

  @doc false
  @impl true
  def run(source_file, params \\ [])

  def run(%SourceFile{filename: "test/" <> _ = filename} = source_file, params) do
    excluded_paths = Params.get(params, :excluded_paths, __MODULE__)

    if not ignore_path?(filename, excluded_paths) and
         (wrong_file_extension?(filename) or
            missing_test_suffix?(filename)) do
      issue =
        source_file
        |> IssueMeta.for(params)
        |> format_issue(message: "Test files should end with `_test.exs`")

      [issue]
    else
      []
    end
  end

  def run(%SourceFile{}, _params), do: []

  defp wrong_file_extension?(filename) do
    filename |> Path.basename() |> String.ends_with?("_test.ex")
  end

  defp missing_test_suffix?(filename) do
    not (filename |> Path.basename(".exs") |> String.ends_with?("_test"))
  end

  defp ignore_path?(filename, excluded_paths) do
    Enum.any?(excluded_paths, &matches?(filename, &1))
  end

  defp matches?(filename, %Regex{} = regex), do: Regex.match?(regex, filename)
  defp matches?(filename, path) when is_binary(path), do: String.starts_with?(filename, path)
end
