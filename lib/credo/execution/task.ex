defmodule Credo.Execution.Task do
  @type t :: module

  @callback call(exec :: Credo.Execution.t(), opts :: Keyword.t()) :: Credo.Execution.t()

  alias Credo.Execution
  alias Credo.Execution.Monitor

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
    Monitor.task(exec, task, opts, &do_run/3, [task, exec, opts])
  end

  def run(task, exec, opts) do
    do_run(task, exec, opts)
  end

  defp do_run(task, %Credo.Execution{halted: false} = exec, opts) do
    old_parent_task = exec.parent_task
    old_current_task = exec.current_task

    exec = Execution.set_parent_and_current_task(exec, exec.current_task, task)

    case task.call(exec, opts) do
      %Execution{halted: false} = exec ->
        exec
        |> Execution.set_parent_and_current_task(old_parent_task, old_current_task)

      %Execution{halted: true} = exec ->
        task.error(exec, opts)
        |> Execution.set_parent_and_current_task(old_parent_task, old_current_task)

      value ->
        # TODO: improve message
        IO.warn("Expected task to return %Credo.Execution{}, got: #{inspect(exec)}")

        value
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
end
