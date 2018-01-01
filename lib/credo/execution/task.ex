defmodule Credo.Execution.Task do
  @type t :: module

  @callback call(exec :: Credo.Execution.t, opts :: Keyword.t) :: Credo.Execution.t

  alias Credo.Execution
  alias Credo.Execution.TaskMonitor

  defmacro __using__(_opts \\ []) do
    quote do
      @behaviour Credo.Execution.Task
      import Credo.Execution
      alias Credo.Execution

      def call(%Execution{halted: false} = exec, opts) do
        exec
      end

      def error(exec, _opts) do
        IO.warn "Execution halted during #{__MODULE__}!"
      end

      defoverridable call: 2
      defoverridable error: 2
    end
  end

  @doc """
  Runs a given `task` if the `Execution` wasn't halted and ensures that the
  result is also an `Execution` struct.
  """
  def run(exec, task, opts \\ [])
  def run(%Credo.Execution{debug: true} = exec, task, opts) do
    TaskMonitor.task(exec, task, opts, &do_run/3, [exec, task, opts])
  end
  def run(exec, task, opts) do
    do_run(exec, task, opts)
  end

  defp do_run(%Credo.Execution{halted: false} = exec, task, opts) do
    case task.call(exec, opts) do
      %Execution{halted: false} = exec ->
        exec
      %Execution{halted: true} = exec ->
        task.error(exec, opts)
      value ->
        # TODO: improve message
        IO.warn "Expected task to return %Credo.Execution{}, got: #{inspect(exec)}"

        value
    end
  end
  defp do_run(%Execution{} = exec, _task, _opts) do
    exec
  end
  defp do_run(exec, _task, _opts) do
    IO.warn "Expected first parameter of Task.run/3 to match %Credo.Execution{}, got: #{inspect(exec)}"

    exec
  end
end
