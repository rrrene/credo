defmodule Credo.CLI.Task.RunChecks do
  @moduledoc false

  use Credo.Execution.Task

  def call(exec, _opts \\ []) do
    # TODO: this could be configurable on `exec` so fancy plugins can ship their own
    runner_mod = Credo.Check.Runner

    {time_run, :ok} =
      :timer.tc(fn ->
        runner_mod.run(exec)
      end)

    put_assign(exec, "credo.time.run_checks", time_run)
  end

  # currently, checks are run async and they load the files relevant to them and
  # then most of them run those files async as well.
  #
  # We might want to flip that and go through files first, filter which checks
  # apply, then aggregate those checks' walks
end
