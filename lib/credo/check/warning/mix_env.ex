defmodule Credo.Check.Warning.MixEnv do
  use Credo.Check,
    id: "EX5010",
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

  @def_ops [:def, :defp, :defmacro]

  @doc false
  def run(%SourceFile{filename: filename} = source_file, params \\ []) do
    ctx = Context.build(source_file, params, __MODULE__)

    case ignore_path?(source_file.filename, ctx.params.excluded_paths) do
      true ->
        []

      false ->
        case Path.extname(filename) do
          ".exs" ->
            []

          _ ->
            result = Credo.Code.prewalk(source_file, &walk/2, ctx)
            result.issues
        end
    end
  end

  for op <- @def_ops do
    # catch variables named e.g. `defp`
    defp walk({unquote(op), _, nil} = ast, ctx) do
      {ast, ctx}
    end

    defp walk({unquote(op), _, _body} = ast, ctx) do
      {ast, Credo.Code.prewalk(ast, &traverse_defs/2, ctx)}
    end
  end

  defp walk(ast, ctx) do
    {ast, ctx}
  end

  defp traverse_defs({{:., _, [{:__aliases__, meta, [:Mix]}, :env]}, _, _arguments} = ast, ctx) do
    {ast, put_issue(ctx, issue_for(ctx, meta))}
  end

  defp traverse_defs(ast, ctx) do
    {ast, ctx}
  end

  defp ignore_path?(filename, excluded_paths) do
    directory = Path.dirname(filename)

    Enum.any?(excluded_paths, &matches?(directory, &1))
  end

  defp matches?(directory, %Regex{} = regex), do: Regex.match?(regex, directory)
  defp matches?(directory, path) when is_binary(path), do: String.starts_with?(directory, path)

  defp issue_for(issue_meta, meta) do
    format_issue(
      issue_meta,
      message: "There should be no calls to `Mix.env` in application code.",
      trigger: "Mix.env",
      line_no: meta[:line],
      column: meta[:column]
    )
  end
end
