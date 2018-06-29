defmodule Credo.CLI.Command do
  @type t :: module

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Credo.CLI.Command

      Module.register_attribute(__MODULE__, :shortdoc, persist: true)

      defp run_task(exec, task), do: Credo.Execution.Task.run(task, exec)
    end
  end

  @doc "Runs the Command."
  @callback call(exec :: Credo.Execution.t(), opts :: List.t()) :: List.t()
end
