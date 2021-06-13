# Creating Plugins

A plugin is basically just a module that provides an `init/1` callback.

```elixir
defmodule CredoDemoPlugin do
  def init(exec) do
    # but what do we do here??
    exec
  end
end
```

The `Credo.Plugin` module provides a number of functions for extending Credo's core features.

```elixir
defmodule CredoDemoPlugin do
  @config_file File.read!(".credo.exs")

  import Credo.Plugin

  def init(exec) do
    exec
    |> register_default_config(@config_file)
    |> register_command("demo", CredoDemoPlugin.DemoCommand)
    |> register_cli_switch(:castle, :string, :X)
    |> append_task(:convert_cli_options_to_config, CredoDemoPlugin.ConvertCliSwitchesToPluginParams)
    |> prepend_task(:set_default_command, CredoDemoPlugin.SetDemoAsDefaultCommand)
  end
end
```

You can find more information on `Credo.Plugin` and the functions imported:

- `Credo.Plugin.register_default_config/2`
- `Credo.Plugin.register_command/3`
- `Credo.Plugin.register_cli_switch/5`
- `Credo.Plugin.append_task/3`
- `Credo.Plugin.append_task/4`
- `Credo.Plugin.prepend_task/3`
- `Credo.Plugin.prepend_task/4`

The demo plugin used in the docs can be found on GitHub and Hex:

- https://github.com/rrrene/credo_demo_plugin
- https://hex.pm/packages/credo_demo_plugin