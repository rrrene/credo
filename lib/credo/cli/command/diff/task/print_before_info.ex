defmodule Credo.CLI.Command.Diff.Task.PrintBeforeInfo do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.CLI.Command.Diff.DiffOutput

  def call(exec, _opts) do
    source_files = Execution.get_source_files(exec)

    DiffOutput.print_before_info(source_files, exec)

    exec
  end
end
