defmodule Credo.CLI.Command.Diff.Output.GitHub do
  @moduledoc false

  alias Credo.CLI.Output.Formatter.GitHub
  alias Credo.Execution

  def print_before_info(_source_files, _exec), do: nil

  def print_after_info(_source_files, exec, _time_load, _time_run) do
    exec
    |> Execution.get_issues()
    |> Enum.filter(&(&1.diff_marker == :new))
    |> GitHub.print_issues()
  end
end
