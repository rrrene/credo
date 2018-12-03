defmodule Credo.CLI.Command.Suggest.Output.Codeclimate do
  alias Credo.CLI.Output.Formatter.Codeclimate
  alias Credo.Execution

  def print_before_info(_source_files, _exec), do: nil

  def print_after_info(_source_files, exec, _time_load, _time_run) do
    exec
    |> Execution.get_issues()
    |> Codeclimate.print_issues(exec.cli_options.path)
  end
end
