defmodule Credo.CLI.Task.RunChecks do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.Check.Runner

  def call(exec, _opts \\ []) do
    source_files = get_source_files(exec)

    {time_run, :ok} =
      :timer.tc(fn ->
        Runner.run(source_files, exec)
      end)

    put_assign(exec, "credo.time.run_checks", time_run)
  end
end
