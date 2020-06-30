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

      @doc """
      Initializes the command.

      This can be used to initialize execution pipelines for the current command:

          def init(exec) do
            Execution.put_pipeline(exec, __MODULE__,
              run_my_thing: [
                {RunMySpecialThing, []}
              ],
              filter_results: [
                {FilterResults, []}
              ],
              print_results: [
                {PrintResultsAndSummary, []}
              ]
            )
          end

      """
      def init(exec), do: exec

      defoverridable init: 1
    end
  end

  @doc "Runs the Command."
  @callback call(exec :: Credo.Execution.t(), opts :: list()) :: Credo.Execution.t()
end
