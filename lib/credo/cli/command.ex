defmodule Credo.CLI.Command do
  @type t :: module

  @doc false
  defmacro __using__(_opts) do
    quote do
      @behaviour Credo.CLI.Command

      Module.register_attribute(__MODULE__, :shortdoc, persist: true)
    end
  end

  @doc "Runs the Command."
  @callback run(exec :: Credo.Execution.t) :: List.t
end
