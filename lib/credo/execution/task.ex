defmodule Credo.Execution.Task do
  @type t :: module

  @callback call(exec :: Credo.Execution.t(), opts :: Keyword.t()) :: Credo.Execution.t()

  require Logger

  alias Credo.Execution
  alias Credo.Execution.ExecutionTiming

  defmacro __using__(_opts \\ []) do
    quote do
      @behaviour Credo.Execution.Task

      import Credo.Execution

      alias Credo.Execution

      def call(%Execution{halted: false} = exec, opts) do
        exec
      end

      def error(exec, _opts) do
        IO.warn("Execution halted during #{__MODULE__}!")

        exec
      end

      defoverridable call: 2
      defoverridable error: 2
    end
  end

  @doc """
  Runs a given `task` if the `Execution` wasn't halted and ensures that the
  result is also an `Execution` struct.
  """
  def run(task, exec, opts \\ [])

  def run(task, %Credo.Execution{debug: true} = exec, opts) do
    run_with_timing(task, exec, opts)
  end

  def run(task, exec, opts) do
    do_run(task, exec, opts)
  end

  defp do_run(task, %Credo.Execution{halted: false} = exec, opts) do
    old_parent_task = exec.parent_task
    old_current_task = exec.current_task

    exec =
      exec
      |> Execution.set_parent_and_current_task(exec.current_task, task)
      |> task.call(opts)
      |> Execution.ensure_execution_struct("#{task}.call/2")

    if exec.halted do
      exec
      |> task.error(opts)
      |> Execution.set_parent_and_current_task(old_parent_task, old_current_task)
    else
      Execution.set_parent_and_current_task(exec, old_parent_task, old_current_task)
    end
  end

  defp do_run(_task, %Execution{} = exec, _opts) do
    exec
  end

  defp do_run(_task, exec, _opts) do
    IO.warn(
      "Expected second parameter of Task.run/3 to match %Credo.Execution{}, " <>
        "got: #{inspect(exec)}"
    )

    exec
  end

  #

  defp run_with_timing(task, exec, opts) do
    context_tuple = {:task, exec, task, opts}
    log(:call_start, context_tuple)

    {started_at, time, exec} = ExecutionTiming.run(&do_run/3, [task, exec, opts])

    log(:call_end, context_tuple, time)

    ExecutionTiming.append(exec, [task: task, parent_task: exec.parent_task], started_at, time)

    exec
  end

  defp log(:call_start, {:task, _exec, task, _opts}) do
    Logger.info("Calling #{task} ...")
  end

  defp log(:call_end, {:task, _exec, task, _opts}, time) do
    Logger.info("Finished #{task} in #{format_time(time)} ...")
  end

  defp format_time(time) do
    cond do
      time > 1_000_000 ->
        "#{div(time, 1_000_000)}s"

      time > 1_000 ->
        "#{div(time, 1_000)}ms"

      true ->
        "#{time}μs"
    end
  end
end
