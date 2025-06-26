defmodule Credo.Check.Warning.UnsafeExec do
  use Credo.Check,
    id: "EX5015",
    base_priority: :high,
    category: :warning,
    explanations: [
      check: """
      Spawning external commands can lead to command injection vulnerabilities.

      Use a safe API where arguments are passed as an explicit list, rather
      than unsafe APIs that run a shell to parse the arguments from a single
      string.

      Safe APIs include:

        * `System.cmd/2,3`
        * `:erlang.open_port/2`, passing `{:spawn_executable, file_name}` as the
          first parameter, and any arguments using the `:args` option

      Unsafe APIs include:

        * `:os.cmd/1,2`
        * `:erlang.open_port/2`, passing `{:spawn, command}` as the first
          parameter

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
      {bad, suggestion, trigger} ->
        [module, _function] = call

        {ast, [issue_for(bad, suggestion, trigger, meta, module, issue_meta) | issues]}

      nil ->
        {ast, issues}
    end
  end

  defp traverse(ast, issues, _issue_meta) do
    {ast, issues}
  end

  defp get_forbidden_call([:os, :cmd], [_]) do
    {":os.cmd/1", "System.cmd/2,3", ":os.cmd"}
  end

  defp get_forbidden_call([:os, :cmd], [_, _]) do
    {":os.cmd/2", "System.cmd/2,3", ":os.cmd"}
  end

  defp get_forbidden_call([:erlang, :open_port], [{:spawn, _}, _]) do
    {":erlang.open_port/2 with `:spawn`", ":erlang.open_port/2 with `:spawn_executable`",
     ":erlang.open_port"}
  end

  defp get_forbidden_call(_, _) do
    nil
  end

  defp issue_for(call, suggestion, trigger, meta, erlang_module, issue_meta) do
    column = meta[:column] - String.length(":#{erlang_module}")

    format_issue(issue_meta,
      message: "Prefer #{suggestion} over #{call} to prevent command injection.",
      trigger: trigger,
      line_no: meta[:line],
      column: column
    )
  end
end
