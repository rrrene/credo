# Creating Plugins

## Basics

A plugin is basically just a module that provides an `init/1` callback, taking a `Credo.Execution` struct as its only parameter and returning a `Credo.Execution`. That's basically it.

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

## Development

Plugins are generally developed by putting them in a Hex package, referencing that package in `mix.exs` and then configuring the plugin in `.credo.exs`.

However, for local development it can be beneficial to develop a plugin inside a project.
But referencing modules from the current Mix project in `.credo.exs` does not work out of the box, because the project is not loaded for every `mix` task.

To be able to use a module from the current project in `.credo.exs`, run `mix app.config` first:

```bash
mix do app.config + credo
```

This way, local plugins can be referenced in `.credo.exs`.

Another, even more pragmatic way to do it is to run `app.config` from `.credo.exs` directly (since it is just a script file):

```elixir
Mix.Task.run("app.config", [])

%{
  configs: [
    %{
      name: "default",
      plugins: [
        {MyProject.CredoPlugin, []}
      ]
    }
  ]
}
```

This should naturally taken with a grain of salt, e.g. taking steps that this is only active during development.

## Further reading

The demo plugin used in the docs can be found on GitHub and Hex:

- https://github.com/rrrene/credo_demo_plugin
- https://hex.pm/packages/credo_demo_plugin
