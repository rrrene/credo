# .credo.exs

Credo is configured via a file called `.credo.exs`.

You can use `mix credo gen.config` to generate a complete example configuration.

```bash
$ mix credo gen.config
* creating .credo.exs
```

This file can live in your project's `config/` or root folder, both is fine.

## Config Keys

Credo's config is a plain `.exs` file, no magic here. It contains a map with a single key (`:configs`), which contains a list of maps that represent the individual configs (most of the time, it's just one, named "default").

```elixir
# .credo.exs or config/.credo.exs
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/", "web/", "apps/"],
        excluded: []
      },
      plugins: [],
      requires: [],
      strict: false,
      parse_timeout: 5000,
      color: true,
      checks: %{
        enabled: [
          {Credo.Check.Design.AliasUsage, priority: :low},
          # ... other checks omitted for readability ...
        ]
      }
    }
  ]
}
```

The config keys available are:

- [`:name`](#name)
- [`:checks`](#checks)
- [`:color`](#color)
- [`:files`](#files)
- [`:parse_timeout`](#parse_timeout)
- [`:plugins`](#plugins)
- [`:requires`](#requires)
- [`:strict`](#strict)

### `:name`

Credo configs are given names. The default configuration is named `default`.

You can specify which config to use on the command line (again, `default` is run by ... default):

```bash
mix credo --config-name <NAME_OF_CONFIG>
```

For example, say we have a directory `lib/that_big_namespace` with tons of issues and we do want to split our regular linting and the necessary clean up in that directory.

We can exclude the directory from our `default` config and add another config for just that directory.

```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/", "web/", "apps/"],
        excluded: ["lib/that_big_namespace"]
      }
    },
    %{
      name: "spring-cleaning",
      files: %{
        included: ["lib/that_big_namespace"],
        excluded: []
      }
    }
  ]
}
```

Now you can use

```bash
mix credo --config-name spring-cleaning
```

to run the custom configuration we added.


### `:checks`

Configures check modules that Credo should load at start up.

Read more about [check configuration](./check_params.md) and [adding custom checks](../custom_checks/adding_checks.md).

#### `:enabled`

Enables *only* the given checks. This is an easy way to pin a project's checks.

```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      checks: %{
        enabled: [
          # this means that only `TabsOrSpaces` will run
          {Credo.Check.Consistency.TabsOrSpaces, []},
        ]
      }
      # files etc.
    }
  ]
}
```

#### `:disabled`

Disables the given checks. This is an easy way to use the default checks, but explicitly disable some you don't need or want.

```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      checks: %{
        disabled: [
          # this means that `TabsOrSpaces` will not run
          {Credo.Check.Consistency.TabsOrSpaces, []},
        ]
      }
      # files etc.
    }
  ]
}
```

This has the added benefit that, when re-enabled via [`--enable-disabled-checks`](suggest_command.html#enable-disabled-checks), check are enabled with their [customized params](./check_params.md).


#### `:extra`

Enables and configures the given checks with the given parameters.

This can be used in a [Credo Plugin](../plugins/creating_plugins.md) to [add a check to the current Credo config](Credo.Plugin.html#register_default_config/2) ([configs are transitive](config_file.html#transitive-configuration-files)) without interfering with what other configs are doing.

```elixir
# a manually registered Config in a Credo Plugin (see links above)
%{
  configs: [
    %{
      name: "default",
      checks: %{
        extra: [
          {MyCredoPlugin.Check.BetterTabsOrSpaces, []},
        ]
      }
      # files etc.
    }
  ]
}
```

This can also be useful in a situation where you want to enable checks for an umbrella, but want to overwrite individual checks in a child app.


```elixir
# my_umbrella/.credo.exs
%{
  configs: [
    %{
      name: "default",
      checks: %{
        enabled: [
          {Credo.Check.Readability.LargeNumbers, []}
        ]
      }
    }
  ]
}

# my_umbrella/apps/my_app2/.credo.exs
%{
  configs: [
    %{
      name: "default",
      checks: %{
        extra: [
          # this means that the checks config from the parent applies,
          # only `LargeNumbers` being configured differently for this project
          {Credo.Check.Readability.LargeNumbers, only_greater_than: 99_999}
        ]
      }
    }
  ]
}
```


### `:color`

Set to `false` to disable colored output (*defaults to `true`*).

This is equivalent to using the `--no-color` CLI switch.

```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      color: false,
      # files, checks etc.
    }
  ]
}
```


### `:files`

```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["mix.exs", "lib/", "src/", "web/", "apps/"],
        excluded: ["test/"]
      },
      # checks etc.
    }
  ]
}
```

The `:files` map can have two fields:

- `:included` contains a list of files, directories and globs (as in `"**/*_test.exs"`)
- `:excluded` contains a list of files, directories, globs (as in `"**/*_test.exs"`) and regular expressions (as in `~r"/_build/"`)


### `:parse_timeout`

Configures a timeout for parsing source files in milliseconds (*defaults to 5000 milliseconds*).

```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      parse_timeout: 60_000,
      # files, checks etc.
    }
  ]
}
```


### `:plugins`

Configures plugin modules that Credo should load at start up (*defaults to `[]`*).

This is needed to [enable and configure plugins](../plugins/using_plugins.md) in the analysis.

```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      plugins: [
        {CredoDemoPlugin, []}
      ],
      # files, checks etc.
    }
  ]
}
```

All plugins are configured using a two-element tuple:

```elixir
{MyApp.PluginModule, params}
```

- `MyApp.PluginModule` - the module representing the plugin to be configured
- `params` - can be either `false` (to disable the plugin) or a keyword list of parameters (to configure the plugin)


### `:requires`

Configures Elixir source files that Credo should require at start up (*defaults to `[]`*).

This is needed to [add local custom checks](../custom_checks/adding_checks.md) in the analysis.

```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      requires: ["lib/check/my_check.ex"],
      # files, checks etc.
    }
  ]
}
```


### `:strict`

Set to `true` to enable low priority checks (*defaults to `false`*).

This is equivalent to using the `--strict` CLI switch.

```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      strict: true,
      # files, checks etc.
    }
  ]
}
```


## Using a custom configuration

You can tell Credo to use a custom config key instead of `default`:

```bash
mix credo --config-name <CONFIG_NAME>
```

For example, given the following config file:

```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      # files, checks etc.
    },
    %{
      name: "picky",
      strict: true,
      # files, checks etc.
    },
  ]
}
```

You can run the `picky` config with this command:

```bash
mix credo --config-name picky
```


## Using a specific configuration file

You can tell Credo to use a specific config file anywhere in the file system:

```bash
mix credo --config-file <PATH_TO_CONFIG_FILE>
```

> #### Note {: .warning}
>
> Specifying a config file this way, only that config file's contents are loaded.
> The "Transitive configuration files" mechanism described in the next section does not apply in this case.


## Transitive configuration files

Credo traverses the filesystem's folder structure upwards to find additional config files which it applies to the current project.

Consider the following directory structure:

```bash
/
  home/
    rrrene/
      projects/
        foo/
          .credo.exs
        bar/
      .credo.exs
```

In this example, there is a Credo config file in my home folder and one in my project.

For project `foo/`, the contents of `/home/rrrene/projects/foo/.credo.exs` are merged with the settings in `/home/rrrene/.credo.exs` and Credo's default config.

For project `bar/`, the contents of `/home/rrrene/.credo.exs` and Credo's default config are relevant.

Please note that, as mentioned above, Credo's config can also reside in a `config/` subdirectory at every step of the way.

Given this directory structure:

```bash
/
  home/
    rrrene/
      config/
        .credo.exs
      projects/
        bar/
        foo/
          config/
            .credo.exs
```

For project `foo/`, the contents of `/home/rrrene/projects/foo/config/.credo.exs` are merged with the settings in `/home/rrrene/config/.credo.exs` and Credo's default config.

This works great for umbrella projects, where you can have individual `.credo.exs` files for each app and/or a global one in the umbrella's `config/` or root folder.
This way, you can enable/disable settings on a per-app basis.
