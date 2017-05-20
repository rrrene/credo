defmodule Credo.Execution.Task.CheckForUpdates do
  use Credo.Execution.Task

  alias Credo.CheckForUpdates

  def call(exec, _opts) do
    # TODO: the CheckForUpdates module could be moved here completely
    CheckForUpdates.run(exec)
  end
end
