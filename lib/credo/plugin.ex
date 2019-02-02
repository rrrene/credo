defmodule Credo.Plugin do
  @moduledoc """
  Plugins can ...

  - add commands
  - add checks, which can add their own issues, with their own categories
  - prepend/append tasks to ProcessDefinitions
  - add CLI options
  - add plugin params

  - override existing commands
    - implement better Explain command
  - override existing CLI options
    - implement a better --strict mode
  - add default config
    - also: change default config, so that an Inch plugin
    - can deactivate the ModuleDoc check in the default config
  - checks with their own categories
  - add format options (?)
  """

  alias Credo.Execution

  def prepend_task(exec, group_name, task_mod) do
    Execution.prepend_task(exec, group_name, task_mod)
  end

  def register_command(exec, name, command_mod) do
    Execution.put_command(exec, name, command_mod)
  end

  def register_cli_switch(exec, name, type, alias_name \\ nil) do
    exec
    |> Execution.put_cli_switch(name, type)
    |> Execution.put_cli_switch_alias(name, alias_name)
  end

  def register_cli_to_config_parser(exec, parser_mod) do
    exec
    |> Execution.append_task(:convert_cli_options_to_config, parser_mod)
  end
end
