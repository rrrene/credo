defmodule Credo.CLI.Task.RunAutocorrect do
  @moduledoc false

  use Credo.Execution.Task

  def call(exec, opts, read_fun \\ &File.read!/1, write_fun \\ &File.write!/2) do
    if exec.autocorrect do
      issues = Keyword.get_lazy(opts, :issues, fn -> Execution.get_issues(exec) end)

      issues
      |> group_by_file
      |> Enum.each(fn {file_path, issues} ->
        file = read_fun.(file_path)

        corrected = Enum.reduce(issues, file, &run_autocorrect(&1, &2, exec))

        write_fun.(file_path, corrected)
      end)
    end

    exec
  end

  defp group_by_file(issues) do
    Enum.reduce(issues, %{}, fn issue, acc ->
      Map.update(acc, issue.filename, [issue], &[issue | &1])
    end)
  end

  defp run_autocorrect(issue, file, exec) do
    case issue.check.autocorrect(file, issue) do
      ^file ->
        file

      corrected_file ->
        Execution.remove_issue(exec, issue)
        corrected_file
    end
  end
end
