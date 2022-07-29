defmodule Credo.Execution.Task do
  @moduledoc """
  A Task is a step in a pipeline, which is given an `Credo.Execution` struct and must return one as well.

  Tasks in a pipeline are only called if they are not "halted" (see `Credo.Execution.halt/2`).

  It implements a `call/1` or `call/2` callback, which is called with the `Credo.Execution` struct
  as first parameter (and the Task's options as the second in case of `call/2`).
  """

  @typedoc false
  @type t :: module

  @doc """
  Is called by the pipeline and contains the Task's actual code.

      defmodule FooTask do
        use Credo.Execution.Task

        def call(exec) do
          IO.inspect(exec)
        end
      end

  The `call/1` functions receives an `exec` struct and must return a (modified) `Credo.Execution`.
  """
  @callback call(exec :: Credo.Execution.t()) :: Credo.Execution.t()

  @doc """
  Works like `call/1`, but receives the options, which are optional when registering the Task, as second argument.

      defmodule FooTask do
        use Credo.Execution.Task

        def call(exec, opts) do
          IO.inspect(opts)

          exec
        end
      end

  """
  @callback call(exec :: Credo.Execution.t(), opts :: Keyword.t()) :: Credo.Execution.t()

  @doc """
  Gets called if `call` holds the execution via `Credo.Execution.halt/1` or `Credo.Execution.halt/2`.
  """
  @callback error(exec :: Credo.Execution.t()) :: Credo.Execution.t()

  @doc """
  Works like `error/1`, but receives the options, which were given during pipeline registration, as second argument.
  """
  @callback error(exec :: Credo.Execution.t(), opts :: Keyword.t()) :: Credo.Execution.t()

  require Logger

  alias Credo.Execution
  alias Credo.Execution.ExecutionTiming

  defmacro __using__(_opts \\ []) do
    quote do
      @behaviour Credo.Execution.Task

      import Credo.Execution

      alias Credo.CLI.Output.UI
      alias Credo.Execution

      @impl true
      def call(%Execution{halted: false} = exec) do
        exec
      end

      @impl true
      def call(%Execution{halted: false} = exec, opts) do
        call(exec)
      end

      @impl true
      def error(exec) do
        case Execution.get_halt_message(exec) do
          "" <> halt_message ->
            command_name = Execution.get_command_name(exec) || "credo"

            UI.warn([:red, "** (#{command_name}) ", halt_message])

          _ ->
            IO.warn("Execution halted during #{__MODULE__}!")
        end

        exec
      end

      @impl true
      def error(exec, _opts) do
        error(exec)
      end

      defoverridable call: 1
      defoverridable call: 2
      defoverridable error: 1
      defoverridable error: 2
    end
  end

  @doc false
  def run(task, exec, opts \\ [])

  def run(task, %Credo.Execution{debug: true} = exec, opts) do
    run_with_timing(task, exec, opts)
  end

  def run(task, %Execution{} = exec, opts) do
    do_run(task, exec, opts)
  end

  def run(_task, exec, _opts) do
    IO.warn(
      "Expected second parameter of Task.run/3 to match %Credo.Execution{}, " <>
        "got: #{inspect(exec)}"
    )

    exec
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

  defp do_run(_task, exec, _opts) do
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
