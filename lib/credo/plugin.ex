defmodule Credo.Plugin do
  def register_module(plugin_mod) do
    Credo.Service.Plugins.put(plugin_mod)
  end

  def register_command(name, command_mod) do
    Credo.Service.Commands.put(name, command_mod)
  end
end
