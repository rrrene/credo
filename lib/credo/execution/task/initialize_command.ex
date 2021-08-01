defmodule Credo.Execution.Task.InitializeCommand do
  @moduledoc false

  alias Credo.Execution

  def call(%Execution{} = exec, _opts) do
    command_name = Execution.get_command_name(exec)
    command_mod = Execution.get_command(exec, command_name)

    init_command(exec, command_mod)
  end

  defp init_command(exec, command_mod) do
    # exec =
    #   exec
    #   |> command_mod.init()
    #   |> Execution.ensure_execution_struct("#{command_mod}.init/1")

    exec =
      command_mod
      |> cli_options_switches()
      |> Enum.reduce(exec, fn {switch_name, switch_type}, exec ->
        Execution.put_cli_switch(exec, command_mod, switch_name, switch_type)
      end)

    command_mod
    |> cli_options_aliases()
    |> Enum.reduce(exec, fn {switch_alias, switch_name}, exec ->
      Execution.put_cli_switch_alias(exec, command_mod, switch_name, switch_alias)
    end)
  end

  defp cli_options_switches(command_mod) do
    command_mod.cli_switches
    |> List.wrap()
    |> Enum.map(fn
      %{name: name, type: type} when is_binary(name) -> {String.to_atom(name), type}
      %{name: name, type: type} when is_atom(name) -> {name, type}
    end)
  end

  defp cli_options_aliases(command_mod) do
    command_mod.cli_switches
    |> List.wrap()
    |> Enum.map(fn
      %{name: name, alias: alias} when is_binary(name) -> {alias, String.to_atom(name)}
      %{name: name, alias: alias} when is_atom(name) -> {alias, name}
      _ -> nil
    end)
    |> Enum.reject(&is_nil/1)
  end
end
