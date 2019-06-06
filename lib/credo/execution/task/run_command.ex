defmodule Credo.Execution.Task.RunCommand do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.Execution

  def call(exec, opts) do
    command_name = Execution.get_command_name(exec)
    command_mod = Execution.get_command(exec, command_name)

    command_mod.call(exec, opts)
  end
end
