defmodule Credo.Test.CheckRunner do
  alias Credo.Execution
  alias Credo.Execution.ExecutionIssues
  alias Credo.SourceFile

  def run_check(source_file, check \\ nil, params \\ []) do
    issues_for(source_file, check, Execution.build(), params)
  end

  defp issues_for(source_files, nil, exec, _) when is_list(source_files) do
    source_files
    |> Enum.flat_map(&get_issues_from_source_file(&1, exec))
    |> Enum.map(fn
      %Credo.Issue{} = issue ->
        issue

      value ->
        raise "Expected %Issue{}, got: #{inspect(value)}"
    end)
  end

  defp issues_for(source_files, check, _exec, params)
       when is_list(source_files) do
    exec = Execution.build()

    if check.run_on_all? do
      :ok = check.run(source_files, exec, params)

      Enum.flat_map(source_files, &get_issues_from_source_file(&1, exec))
    else
      source_files
      |> check.run(params)
      |> Enum.flat_map(&get_issues_from_source_file(&1, exec))
    end
  end

  defp issues_for(%SourceFile{} = source_file, nil, exec, _) do
    get_issues_from_source_file(source_file, exec)
  end

  defp issues_for(%SourceFile{} = source_file, check, _exec, params) do
    _issues = check.run(source_file, params)
  end

  defp get_issues_from_source_file(source_file, exec) do
    ExecutionIssues.get(exec, source_file)
  end
end
