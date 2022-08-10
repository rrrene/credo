defmodule Credo.CLI.Command.Diff.Output.Github do
  @moduledoc false

  alias Credo.CLI.Output.Formatter.Github
  alias Credo.Execution

  def print_before_info(_source_files, _exec), do: nil

  def print_after_info(_source_files, exec, _time_load, _time_run) do
    exec
    |> Execution.get_issues()
    |> Github.print_issues()
  end
end
