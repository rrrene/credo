defmodule Credo.Execution.TaskGroupBuilder do
  defmacro __using__(_opts \\ []) do
    quote do
      import Credo.Execution.TaskGroupBuilder
      Module.register_attribute(__MODULE__, :tasks, accumulate: true)
      @before_compile Credo.Execution.TaskGroupBuilder

      def call(exec, opts \\ []) do
        task_builder_call(exec, opts)
      end
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      defp task_builder_call(exec, opts) do
        tasks = Enum.reverse(@tasks)

        Enum.reduce(tasks, exec, fn(task, exec) ->
          #IO.inspect({:task, task})

          Credo.Execution.Task.run(exec, task, opts)
        end)
      end
    end
  end

  defmacro task(atom) do
    quote do
      @tasks unquote(atom)
    end
  end
end
