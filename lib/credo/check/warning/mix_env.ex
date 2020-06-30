defmodule Credo.Check.Warning.MixEnv do
  use Credo.Check,
    base_priority: :high,
    param_defaults: [excluded_paths: []],
    explanations: [
      check: """
      Mix is a build tool and, as such, it is not expected to be available in production.
      Therefore, it is recommended to access Mix.env only in configuration files and inside
      mix.exs, never in your application code (lib).

      (from the Elixir docs)
      """,
      params: [
        excluded_paths: "List of paths or regex to exclude from this check"
      ]
    ]

  alias Credo.SourceFile

  @call_string "Mix.env"

  @doc false
  def run(%SourceFile{filename: filename} = source_file, params \\ []) do
    excluded_paths = Params.get(params, :excluded_paths, __MODULE__)

    case ignore_path?(source_file.filename, excluded_paths) do
      true ->
        []

      false ->
        issue_meta = IssueMeta.for(source_file, params)

        filename
        |> Path.extname()
        |> case do
          ".exs" -> []
          _ -> Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
        end
    end
  end

  # Check if analyzed module path is within ignored paths
  defp ignore_path?(filename, excluded_paths) do
    directory = Path.dirname(filename)

    Enum.any?(excluded_paths, &matches?(directory, &1))
  end

  defp matches?(directory, %Regex{} = regex), do: Regex.match?(regex, directory)
  defp matches?(directory, path) when is_binary(path), do: String.starts_with?(directory, path)

  defp traverse(
         {{:., _, [{:__aliases__, _, [:Mix]}, :env]}, meta, _arguments} = ast,
         issues,
         issue_meta
       ) do
    {ast, issues_for_call(meta, issues, issue_meta)}
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp issues_for_call(meta, issues, issue_meta) do
    [issue_for(issue_meta, meta[:line], @call_string) | issues]
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(
      issue_meta,
      message: "There should be no calls to Mix.env in application code.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
