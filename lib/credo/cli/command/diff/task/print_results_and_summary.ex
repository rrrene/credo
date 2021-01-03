defmodule Credo.CLI.Command.Diff.Task.PrintResultsAndSummary do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.CLI.Command.Diff.DiffOutput

  def call(exec, _opts) do
    source_files = Execution.get_source_files(exec)

    time_load = Execution.get_assign(exec, "credo.time.source_files")
    time_run = Execution.get_assign(exec, "credo.time.run_checks")

    DiffOutput.print_after_info(source_files, exec, time_load, time_run)

    exec
  end
end
