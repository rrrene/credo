defmodule Credo.Test.CheckRunner do
  alias Credo.Execution
  alias Credo.Execution.ExecutionIssues

  def run_check(source_files, check, params \\ []) do
    exec = Execution.build()

    source_files
    |> List.wrap()
    |> issues_for(check, exec, params)
  end

  defp issues_for(source_files, check, exec, params)
       when is_list(source_files) do
    :ok = check.run_on_all_source_files(exec, source_files, params)

    Enum.flat_map(source_files, &get_issues_from_source_file(&1, exec))
  end

  defp get_issues_from_source_file(source_file, exec) do
    ExecutionIssues.get(exec, source_file)
  end
end
