defmodule Credo.Plugin do
  # TODO: add format options (?)

  alias Credo.Execution

  def append_task(%Execution{initializing_plugin: plugin_mod} = exec, group_name, task_mod) do
    Execution.append_task(exec, plugin_mod, nil, group_name, task_mod)
  end

  def append_task(
        %Execution{initializing_plugin: plugin_mod} = exec,
        pipeline_key,
        group_name,
        task_mod
      ) do
    Execution.append_task(exec, plugin_mod, pipeline_key, group_name, task_mod)
  end

  def prepend_task(%Execution{initializing_plugin: plugin_mod} = exec, group_name, task_mod) do
    Execution.prepend_task(exec, plugin_mod, nil, group_name, task_mod)
  end

  def prepend_task(
        %Execution{initializing_plugin: plugin_mod} = exec,
        pipeline_key,
        group_name,
        task_mod
      ) do
    Execution.prepend_task(exec, plugin_mod, pipeline_key, group_name, task_mod)
  end

  # register_cli_switch(exec, :castle, :string, :X, false | true | :other_castle)
  def register_cli_switch(
        %Execution{initializing_plugin: plugin_mod} = exec,
        name,
        type,
        alias_name \\ nil,
        convert_to_param \\ true
      ) do
    exec
    |> Execution.put_cli_switch(plugin_mod, name, type)
    |> Execution.put_cli_switch_alias(plugin_mod, name, alias_name)
    |> Execution.put_cli_switch_plugin_param_converter(plugin_mod, name, convert_to_param)
  end

  @doc """
  Registers and initializes a Command module with a given `name`.
  """
  def register_command(%Execution{initializing_plugin: plugin_mod} = exec, name, command_mod) do
    Execution.put_command(exec, plugin_mod, name, command_mod)
  end

  def register_default_config(
        %Execution{initializing_plugin: plugin_mod} = exec,
        config_file_string
      ) do
    Execution.append_config_file(exec, {:plugin, plugin_mod, config_file_string})
  end
end
