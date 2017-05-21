defmodule Credo.Execution.TaskGroup do
  @type t :: module

  @callback call(exec :: Credo.Execution.t, opts :: Keyword.t) :: Credo.Execution.t

  import Credo.Execution

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
        Enum.reduce(all_tasks(), exec, fn(task, exec) ->
          #IO.inspect({:task, task})

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
  def run(exec, task_group, opts) do
    {time, exec} =
      :timer.tc fn ->
        task_group.call(exec, opts)
      end

    put_assign(exec, "credo.time.group.#{task_group.name}", time)
  end
end
