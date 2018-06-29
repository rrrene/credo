defmodule Credo.Execution.ProcessDefinition do
  alias Credo.Execution

  @doc false
  defmacro __using__(_opts \\ []) do
    quote do
      Module.register_attribute(__MODULE__, :tasks, accumulate: true)

      @before_compile Credo.Execution.ProcessDefinition

      use Credo.Execution.Task

      import Credo.Execution.ProcessDefinition

      def call(exec, opts \\ []) do
        process_definition_call(exec)
      end
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      defp process_definition_call(exec) do
        Credo.Execution.ProcessDefinition.builder_call(exec, all_tasks(), __MODULE__)
      end

      defp all_tasks do
        Enum.reverse(@tasks)
      end
    end
  end

  @doc false
  def builder_call(exec, compiled_tasks, current_task) do
    old_parent_task = exec.parent_task
    old_current_task = exec.current_task

    exec = Execution.set_parent_and_current_task(exec, exec.current_task, current_task)

    tasks = compiled_tasks

    Enum.reduce(tasks, exec, fn task, exec ->
      Credo.Execution.Task.run(task, exec)
    end)
    |> Execution.set_parent_and_current_task(old_parent_task, old_current_task)
  end

  @doc """
  Creates a TaskGroup with the given `name`, which can be called via `.call/2`.
  """
  defmacro activity(name, do_block)

  defmacro activity(name, do: block) do
    env = __CALLER__
    module_name = :"#{env.module}.#{Macro.camelize(to_string(name))}"

    quote do
      @tasks unquote(module_name)

      defmodule unquote(module_name) do
        use Credo.Execution.ProcessDefinition

        unquote(block)
      end
    end
  end

  @doc """
  Registers a Task module with the current task group.
  """
  defmacro run(module)

  defmacro run(module) do
    quote do
      @tasks unquote(module)
    end
  end
end
