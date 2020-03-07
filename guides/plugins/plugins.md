# Plugins 101

Plugins can provide additional functionality to Credo.

This functionality can include:

- adding new commands
- overriding existing commands (e.g. implement better Explain command)
- modifying the default config
- adding checks, which can add their own issues, with their own categories,
- prepending/appending steps to Credo's execution process
- adding new CLI options

### Using plugins

Plugins are just modules. Most of the time, a Credo plugin will be published on Hex. You include it as a dependency:

```elixir
{:credo_demo_plugin, "~> 0.1.0"},
```

Plugins, like checks, are just modules and functions.
They can be included by listing them under the `:plugins` field in Credo's configuration file.

```elixir
%{
  configs: [
    %{
      name: "default",
      plugins: [
        {CredoDemoPlugin, []}
      ]
    }
  ]
}
```

### Configuring plugins

Plugins can be configured via params, just like checks.
Each entry consists of a two-element tuple: the plugin's module and a keyword list of parameters, which can be used to configure the plugin itself.

```elixir
%{
  configs: [
    %{
      name: "default",
      plugins: [
        {CredoDemoPlugin, [castle: "Grayskull"]}
      ]
    }
  ]
}
```

Plugins can be deactivated by setting the second tuple element to `false`.

```elixir
%{
  configs: [
    %{
      name: "default",
      plugins: [
        {CredoDemoPlugin, []},
        {CredoYetAnotherPlugin, false} # <-- don't load this for now
      ]
    }
  ]
}
```

### Creating a plugin

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

### Add new commands

Commands are just modules with a call function and adding new commands is easy.

```elixir
# credo_demo_plugin.ex
defmodule CredoDemoPlugin do
  import Credo.Plugin

  def init(exec) do
    register_command(exec, "demo", CredoDemoPlugin.DemoCommand)
  end
end
```

```elixir
# credo_demo_plugin/demo_command.ex
defmodule CredoDemoPlugin.DemoCommand do
  alias Credo.CLI.Output.UI
  alias Credo.Execution

  def call(exec, _) do
    castle = Execution.get_plugin_param(exec, CredoPlus, :castle)

    UI.puts("By the power of #{castle}!")

    exec
  end
end
```

Users can use this command by typing

```bash
$ mix credo demo
By the power of !
```

### Override an existing command

Since commands are just modules with a call function, overriding existing commands is easy.

```elixir
defmodule CredoDemoPlugin do
  import Credo.Plugin

  def init(exec) do
    register_command(exec, "explain", CredoDemoPlugin.MyBetterExplainCommand)
  end
end
```

This example would have the effect that typing `mix credo lib/my_file.ex:42` would no longer run the built-in `Explain` command, but rather our plugin's `MyBetterExplain` command.

### Modifying the default config

Plugins can add default configuration to Credo.

```elixir
defmodule CredoDemoPlugin do
  import Credo.Plugin

  def init(exec) do
    register_default_config(exec, @config_file)
  end
end
```

The configuration's loading order is this:

1. Credo's own default config
2. Default configs added by plugins
3. Config files in the user's file system

Config values set in later stages are overwriting values from earlier ones.

### Adding checks

To add checks from your plugin, simply extend the default config ...

```elixir
# credo_demo_plugin.ex
defmodule CredoDemoPlugin do
  @config_file File.read!(".credo.exs")

  import Credo.Plugin

  def init(exec) do
    register_default_config(exec, @config_file)
  end
end
```

... and then add the new checks there:

```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      checks: [
        {CredoDemoPlugin.MyNewCheck, []}
      ]
    }
  ]
}
```

Since we are extending the default config, we can also deactivate checks and "replace" them with new ones:

```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      checks: [
        {Credo.Check.Readability.ModuleDoc, false},
        {CredoDemoPlugin.BetterModuleDoc, []}
      ]
    }
  ]
}
```

### Inserting tasks into Credo's execution process

Credo's execution process consists of several steps, each with a set of tasks, which you can hook into.

Prepending or appending tasks to these steps is easy:

```elixir
# credo_demo_plugin.ex
defmodule CredoDemoPlugin do
  import Credo.Plugin

  def init(exec) do
    prepend_task(exec, :set_default_command, CredoDemoPlugin.SetDemoAsDefaultCommand)
  end
end
```

```elixir
# credo_demo_plugin/set_demo_as_default_command.ex
defmodule CredoPlus.SetDemoAsDefaultCommand do
  use Credo.Execution.Task

  alias Credo.CLI.Options

  def call(exec, _opts) do
    set_command(exec, exec.cli_options.command || "demo")
  end

  defp set_command(exec, command) do
    %Execution{exec | cli_options: %Options{exec.cli_options | command: command}}
  end
end
```

This example would have the effect that typing `mix credo` would no longer run the built-in `Suggest` command, but rather our plugin's `Demo` command.

### Adding new CLI options

We saw how plugins can be configured via params in the "Configuring plugins" section:

```elixir
{CredoDemoPlugin, [castle: "Grayskull"]}
```

But what about those situations where we want to be able to configure things on-the-fly via the CLI?
Plugins should be able to provide custom CLI options as well, so we can do something like:

```bash
$ mix credo --castle Winterfell
Unknown switch: --castle
```

Registering a custom CLI switch is easy:

```elixir
defmodule CredoDemoPlugin do
  import Credo.Plugin

  def init(exec) do
    register_cli_switch(exec, :castle, :string, :X)
  end
end
```

Of course, having a CLI option is not worth much if we can not utilize it.
This is why every registered CLI switch is automatically converted into a plugin param of the same name.

```bash
$ mix credo --castle Winterfell
By the power of Winterfell!
```

Plugin authors can also provide a function to control the plugin param's name and value more granularly:

```elixir
defmodule CredoDemoPlugin do
  import Credo.Plugin

  def init(exec) do
    register_cli_switch(exec, :kastle, :string, :K, fn(switch_value) ->
      {:castle, switch_value}
    end)
  end
end
```
