defmodule Credo.Execution.TaskRunnerBuilder do

  @doc false
  defmacro __using__(_opts \\ []) do
    quote do
      import Credo.Execution.TaskRunnerBuilder
      Module.register_attribute(__MODULE__, :groups, accumulate: true)
      @before_compile Credo.Execution.TaskRunnerBuilder

      def call(exec) do
        runner_builder_call(exec)
      end
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      defp runner_builder_call(exec) do
        Credo.Execution.TaskRunnerBuilder.builder_call(exec, all_groups())
      end

      defp all_groups do
        Enum.reverse(@groups)
      end
    end
  end


  @doc """
  Called internally by `router_builder_call`.
  """
  def builder_call(exec, compiled_groups) do
    groups = compiled_groups

    #IO.inspect({:executing_router_with_groups, __MODULE__, groups})

    Enum.reduce(groups, exec, fn(group, exec) ->
      #IO.puts ""
      #IO.inspect({:group, group})
      Credo.Execution.TaskGroup.run(exec, group)
    end)
  end


  @doc """
  Creates a TaskGroup with the given `name`, which can be called via `.call/2`.
  """
  defmacro group(name, group_opts) do
    module_name = :"Credo.Execution.TaskGroups.#{name}"
    group_name = name

    quote do
      @groups unquote(module_name)

      defmodule unquote(module_name) do
        use Credo.Execution.TaskGroup

        unquote(group_opts[:do])

        def name, do: unquote(group_name)
      end
    end
  end

end
