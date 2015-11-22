defmodule Credo.CLI.Command do
  @doc false
  defmacro __using__(_opts) do
    quote do
      Module.register_attribute(__MODULE__, :shortdoc, persist: true)
    end
  end
end
