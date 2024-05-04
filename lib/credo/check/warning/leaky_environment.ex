defmodule Credo.Check.Warning.LeakyEnvironment do
  use Credo.Check,
    id: "EX5008",
    base_priority: :high,
    tags: [:controversial],
    category: :warning,
    explanations: [
      check: """
      OS child processes inherit the environment of their parent process. This
      includes sensitive configuration parameters, such as credentials. To
      minimize the risk of such values leaking, clear or overwrite them when
      spawning executables.

      The functions `System.cmd/2` and `System.cmd/3` allow environment variables be cleared by
      setting their value to `nil`:

          System.cmd("env", [], env: %{"DB_PASSWORD" => nil})

      """
    ]

  @doc false
  @impl true
  def run(%SourceFile{} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, issue_meta))
  end

  defp traverse({{:., meta, call}, _, args} = ast, issues, issue_meta) do
    case get_forbidden_call(call, args) do
      nil ->
        {ast, issues}

      {trigger, meta} ->
        {ast, [issue_for(issue_meta, meta, trigger) | issues]}

      "" <> trigger ->
        [module, _function] = call

        {ast, [issue_for(issue_meta, meta, trigger, module) | issues]}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp get_forbidden_call([{:__aliases__, meta, [:System]}, :cmd], [_, _]) do
    {"System.cmd", meta}
  end

  defp get_forbidden_call([{:__aliases__, meta, [:System]}, :cmd], [_, _, opts])
       when is_list(opts) do
    if not Keyword.has_key?(opts, :env) do
      {"System.cmd", meta}
    end
  end

  defp get_forbidden_call([:erlang, :open_port], [_, opts]) when is_list(opts) do
    if not Keyword.has_key?(opts, :env) do
      ":erlang.open_port"
    end
  end

  defp get_forbidden_call(_, _) do
    nil
  end

  defp issue_for(issue_meta, meta, trigger, erlang_module \\ nil) do
    column =
      if erlang_module do
        meta[:column] - String.length(":#{erlang_module}")
      else
        meta[:column]
      end

    format_issue(
      issue_meta,
      message: "When using #{trigger}, clear or overwrite sensitive environment variables.",
      trigger: trigger,
      line_no: meta[:line],
      column: column
    )
  end
end
