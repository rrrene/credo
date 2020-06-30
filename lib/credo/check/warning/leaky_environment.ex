defmodule Credo.Check.Warning.LeakyEnvironment do
  use Credo.Check,
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

  defp traverse({{:., _loc, call}, meta, args} = ast, issues, issue_meta) do
    case get_forbidden_call(call, args) do
      nil ->
        {ast, issues}

      bad ->
        {ast, issues_for_call(bad, meta, issue_meta, issues)}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp get_forbidden_call([{:__aliases__, _, [:System]}, :cmd], [_, _]) do
    "System.cmd/2"
  end

  defp get_forbidden_call([{:__aliases__, _, [:System]}, :cmd], [_, _, opts])
       when is_list(opts) do
    if Keyword.has_key?(opts, :env) do
      nil
    else
      "System.cmd/3"
    end
  end

  defp get_forbidden_call([:erlang, :open_port], [_, opts])
       when is_list(opts) do
    if Keyword.has_key?(opts, :env) do
      nil
    else
      ":erlang.open_port/2"
    end
  end

  defp get_forbidden_call(_, _) do
    nil
  end

  defp issues_for_call(call, meta, issue_meta, issues) do
    options = [
      message: "When using #{call}, clear or overwrite sensitive environment variables",
      trigger: call,
      line_no: meta[:line]
    ]

    [format_issue(issue_meta, options) | issues]
  end
end
