defmodule Credo.Execution.Task.RunCommand do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.Execution

  @exit_status Credo.CLI.ExitStatus.generic_error()

  def call(exec, opts) do
    command_name = Execution.get_command_name(exec)
    command_mod = Execution.get_command(exec, command_name)

    command_mod.call(exec, opts)
  end

  def error(exec, _opts) do
    case get_exit_status(exec) do
      0 -> put_exit_status(exec, @exit_status)
      _ -> exec
    end
  end
end
