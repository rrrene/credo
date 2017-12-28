defmodule Credo.Execution.Task.RunCommand do
  use Credo.Execution.Task

  alias Credo.CLI

  def call(exec, opts) do
    command_name = Execution.get_command_name(exec)
    command_mod = CLI.command_for(command_name)

    command_mod.call(exec, opts)
  end
end
