defmodule Credo.Execution.Task.InitializePlugins do
  @moduledoc false

  use Credo.Execution.Task

  alias Credo.Execution

  def call(exec, _opts) do
    Enum.reduce(exec.plugins, exec, &init_plugin(&2, &1))
  end

  defp init_plugin(exec, {_mod, false}), do: exec

  defp init_plugin(exec, {mod, _params}) do
    if Code.ensure_loaded?(mod) do
      if function_exported?(mod, :init, 1) do
        exec
        |> Execution.set_initializing_plugin(mod)
        |> mod.init()
        |> Execution.ensure_execution_struct("#{mod}.init/1")
        |> Execution.set_initializing_plugin(nil)
      else
        Execution.halt(
          exec,
          "Plugin module `#{Credo.Code.Module.name(mod)}` is not a valid plugin: does not implement expected behavior."
        )
      end
    else
      Execution.halt(
        exec,
        "Plugin module `#{Credo.Code.Module.name(mod)}` is not available and could not be initialized."
      )
    end
  end
end
