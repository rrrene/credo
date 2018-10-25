defmodule Credo.CLI.Command do
  @moduledoc """
  `Command` is used to describe commands which can be executed from the command line.

  The default command is `Credo.CLI.Command.Suggest.SuggestCommand`.

  A basic command that writes "Hello World" can be implemented like this:

      defmodule HelloWorldCommand do
        use Credo.CLI.Command

        def call(_exec, _opts) do
          Credo.CLI.Output.UI.puts([:yellow, "Hello ", :orange, "World"])
        end
      end

  """

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
