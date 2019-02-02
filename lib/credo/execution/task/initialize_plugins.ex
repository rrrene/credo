defmodule Credo.Execution.Task.InitializePlugins do
  @moduledoc false

  alias Credo.Execution

  def call(exec, _opts) do
    Enum.reduce(exec.plugins, exec, &init_plugin(&2, &1))
  end

  defp init_plugin(exec, {mod, params}) do
    case mod.init(exec, params) do
      %Execution{} = exec ->
        exec

      value ->
        raise "Expected #{mod}.init/1 to return %Credo.Execution{}, got: #{inspect(value)}"
    end
  end
end
