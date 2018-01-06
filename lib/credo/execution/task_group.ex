defmodule Credo.Execution.TaskGroup do
  @type t :: module

  @callback call(exec :: Credo.Execution.t(), opts :: Keyword.t()) ::
              Credo.Execution.t()

  alias Credo.Execution.TaskMonitor

  defmacro __using__(_opts \\ []) do
    quote do
      import Credo.Execution.TaskGroup
      Module.register_attribute(__MODULE__, :tasks, accumulate: true)
      @before_compile Credo.Execution.TaskGroup

      def call(exec, opts \\ []) do
        task_builder_call(exec, opts)
      end
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      defp task_builder_call(exec, opts) do
        Enum.reduce(all_tasks(), exec, fn task, exec ->
          Credo.Execution.Task.run(exec, task, opts)
        end)
      end

      defp all_tasks do
        Enum.reverse(@tasks)
      end
    end
  end

  @doc """
  Registers a task module with the current task group.
  """
  defmacro task(atom) do
    quote do
      @tasks unquote(atom)
    end
  end

  @doc """
  Runs a given `task_group`.
  """
  def run(exec, task_group, opts \\ [])

  def run(%Credo.Execution{debug: true} = exec, task_group, opts) do
    TaskMonitor.task_group(exec, task_group, opts, &do_run/3, [
      exec,
      task_group,
      opts
    ])
  end

  def run(exec, task_group, opts) do
    do_run(exec, task_group, opts)
  end

  defp do_run(exec, task_group, opts) do
    task_group.call(exec, opts)
  end
end
