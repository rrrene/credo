defmodule Credo.Execution.Task.RunCommand do
  use Credo.Execution.Task

  alias Credo.CLI

  def call(exec, _opts) do
    CLI.command_for(exec.cli_options.command).run(exec)
  end
end
