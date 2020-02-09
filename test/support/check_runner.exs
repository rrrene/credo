defmodule Credo.Test.CheckRunner do
  use ExUnit.Case

  alias Credo.Execution.ExecutionIssues
  alias Credo.SourceFile

  def run_check(source_file, check \\ nil, params \\ []) do
    issues_for(source_file, check, create_execution(), params)
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
    exec = create_execution()

    if check.run_on_all? do
      :ok = check.run(source_files, exec, params)

      source_files
      |> Enum.flat_map(&(&1 |> get_issues_from_source_file(exec)))
    else
      source_files
      |> check.run(params)
      |> Enum.flat_map(&(&1 |> get_issues_from_source_file(exec)))
    end
  end

  defp issues_for(%SourceFile{} = source_file, nil, exec, _) do
    source_file |> get_issues_from_source_file(exec)
  end

  defp issues_for(%SourceFile{} = source_file, check, _exec, params) do
    _issues = check.run(source_file, params)
  end

  defp create_execution do
    Credo.Execution.build()
  end

  defp get_issues_from_source_file(source_file, exec) do
    ExecutionIssues.get(exec, source_file)
  end
end
