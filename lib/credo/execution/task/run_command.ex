defmodule Credo.Execution.Task.RunCommand do
  use Credo.Execution.Task

  alias Credo.CLI

  def call(exec, _opts) do
    command_name = Execution.get_command_name(exec)
    command_mod = CLI.command_for(command_name)

    command_mod.run(exec)
  end
end
