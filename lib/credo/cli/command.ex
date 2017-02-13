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
  @callback run(config :: Credo.Config.t) :: List.t
end
