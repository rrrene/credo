defmodule Credo.Execution.ProcessDefinition do
  @moduledoc """
  A `ProcessDefinition` can be used to define a process which consists of
  several tasks and can be called with a `Credo.Execution` struct.

      defmodule Credo.ExampleProcess do
        use Credo.Execution.ProcessDefinition

        run Credo.Task.ParseOptions
        run Credo.Task.ValidateOptions
        run Credo.Task.RunCommand
        run Credo.Task.AssignExitStatus
      end

  All modules registered with `run/1` will be executed in order when the process is called (a bit like a Plug pipeline):

      argv = ["command", "line", "--arguments"]
      exec = Credo.Execution.build(argv)

      Credo.ExampleProcess.call(exec)

  For convenience, tasks belonging together semantically can be grouped using `actvity/2`:

      defmodule Credo.ExampleProcess do
        use Credo.Execution.ProcessDefinition

        activity :prepare_analysis do
          run Credo.Task.ParseOptions
          run Credo.Task.ValidateOptions
        end

        activity :run_analysis do
          run Credo.Task.RunCommand
          run Credo.Task.AssignExitStatus
        end
      end

  Each task receives an Execution struct and returns an Execution struct upon completion.
  Any Task can mark the Execution as "halted" to stop Credo's execution.
  Subsequent Tasks won't be run in this case.

  """

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

    compiled_tasks
    |> Enum.reduce(exec, fn task, exec ->
      Credo.Execution.Task.run(task, exec)
    end)
    |> Execution.set_parent_and_current_task(old_parent_task, old_current_task)
  end

  @doc """
  Creates a group of tasks (an "activity") with the given `name`.

  Activities are called in order when the surrounding process is called.
  """
  defmacro activity(name, do_block)

  defmacro activity(name, do: block) do
    env = __CALLER__
    module_name = :"#{env.module}.#{Macro.camelize(to_string(name))}"

    quote do
      @tasks unquote(module_name)

      defmodule unquote(module_name) do
        @moduledoc false

        use Credo.Execution.ProcessDefinition

        unquote(block)

        # Tasks declared via the `activity` macro are not handling errors by default
        def error(exec, _opts), do: exec
      end
    end
  end

  @doc """
  Registers a Task module with the current process.

  Tasks are called in order when the surrounding process or activity is called.
  """
  defmacro run(module)

  defmacro run(module) do
    quote do
      @tasks unquote(module)
    end
  end
end
