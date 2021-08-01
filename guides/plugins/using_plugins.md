# Using Plugins

### Installing plugins

Plugins are just modules.

Plugins can be included by listing them under the `:plugins` field `.credo.exs`:

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

Most of the time, a Credo plugin will be published on Hex. You include it as a dependency in `mix.exs` like any other dependency:

```elixir
{:credo_demo_plugin, "~> 0.1.0"},
```

Plugins, like checks, are just modules and functions. They are enabled in Credo's configuration file `.credo.exs`, which you can generate via `mix credo gen.config`:

```bash
$ mix credo gen.config
* creating .credo.exs
```

The demo plugin adds a command called "demo":

```bash
$ mix credo demo
By the power of !
```

It seems like there's something missing before the `!` ...

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

```bash
$ mix credo demo
By the power of Grayskull!
```

Just in case, Plugins can be deactivated by setting the second tuple element to `false`.

```elixir
%{
  configs: [
    %{
      name: "default",
      plugins: [
        {CredoDemoPlugin, false} # <-- don't load this for now
      ]
    }
  ]
}
```

The demo plugin used in the docs can be found on GitHub and Hex:

- https://github.com/rrrene/credo_demo_plugin
- https://hex.pm/packages/credo_demo_plugin
