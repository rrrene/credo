defmodule Credo.CLI.Command.List.Output.Oneline do
  @moduledoc false

  alias Credo.CLI.Output.Formatter.Oneline
  alias Credo.Execution

  def print_before_info(_source_files, _exec), do: nil

  def print_after_info(_source_files, exec, _time_load, _time_run) do
    exec
    |> Execution.get_issues()
    |> Oneline.print_issues()
  end
end
