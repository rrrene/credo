defmodule Credo.Check.CodePattern do
  @callback property_value :: any
  @callback property_value_for(any, any) :: any

  defmacro __using__(_) do
    quote do
      @behaviour Credo.Check.CodePattern

      alias Credo.SourceFile
      alias Credo.Check.PropertyValue
    end
  end
end
