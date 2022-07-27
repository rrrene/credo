defmodule Credo.CLI.Task.RunAutocorrect do
  @moduledoc false

  use Credo.Execution.Task

  def call(exec, opts) do
    issues = Keyword.get_lazy(opts, :issues, fn -> Execution.get_issues(exec) end)

    issues
    |> group_by_file
    |> Enum.each(fn {file_name, issues} ->
      file = File.read!(file_name)
      Enum.reduce(issues, file, fn issue, corrected_file ->
        issue.check.autocorrect(corrected_file)
      end)
    end)

    exec
  end

  defp group_by_file(issues) do
    Enum.reduce(issues, %{}, fn issue, acc ->
      Map.update(acc, issue.filename, [issue], &[issue | &1])
    end)
  end
end
