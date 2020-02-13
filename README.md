# Credo [![Build Status](https://travis-ci.org/rrrene/credo.svg?branch=master)](https://travis-ci.org/rrrene/credo) [![Inline docs](https://inch-ci.org/github/rrrene/credo.svg?branch=master)](https://inch-ci.org/github/rrrene/credo)

Credo is a static code analysis tool for the Elixir language with a focus on teaching and code consistency.

## What can it do?

`credo` can show you refactoring opportunities in your code, complex code fragments, warn you about common mistakes, show inconsistencies in your naming scheme and - if needed - help you enforce a desired coding style.


![Credo](https://raw.github.com/rrrene/credo/master/assets/screenshot.png)


## Installation

The easiest way to add Credo to your project is by [using Mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html).

Add `:credo` as a dependency to your project's `mix.exs`:

```elixir
defp deps do
  [
    {:credo, "~> 1.2", only: [:dev, :test], runtime: false}
  ]
end
```

And run:

    $ mix deps.get



## Basic Usage

To run credo in the current project, **just type**:

    $ mix credo

This will run the code analysis and suggest places to edit your code.

**If you want to enforce a style guide** and need a more traditional linting experience, try

    $ mix credo --strict

and continue reading in the Configuration section.



If you want the **list of issues grouped by files** instead of suggestions just type:

    $ mix credo list

You will get output like this:

    ┃ Refactoring opportunities
    ┃
    ┃ [R] ↗ If/else blocks should not have a negated condition in `if`.
    ┃       lib/phoenix/channel.ex:26 (Phoenix.Channel.subscribe)
    ┃ [R] → Function is too complex (max ABC is 15, was 43).
    ┃       lib/phoenix/router.ex:563:8 (Phoenix.Router.add_resources)
    ┃ [R] → Function is too complex (max ABC is 15, was 16).
    ┃       lib/phoenix/router/socket.ex:12:12 (Phoenix.Router.Socket.channel)
    ┃

Now you might want to know more about that particular entry, **just copy the filename+line-number combo into the command**:

    $ mix credo lib/phoenix/channel.ex:26

    ┃ Phoenix.Channel
    ┃
    ┃   [R] Category: refactor
    ┃    ↗  Priority: medium
    ┃
    ┃       If/else blocks should not have a negated condition in `if`.
    ┃       lib/phoenix/channel.ex:26 (Phoenix.Channel.subscribe)
    ┃
    ┃    __ CODE IN QUESTION
    ┃
    ┃       if !Socket.authenticated?(socket, channel, topic) do
    ┃
    ┃    __ WHY IT MATTERS
    ┃
    ┃       An `if` block with a negated condition should not contain an else block.
    ┃
    ┃       So while this is fine:
    ┃
    ┃           if !allowed? do
    ┃             raise "Not allowed!"
    ┃           end
    ┃
    ┃       The code in this example ...
    ┃
    ┃           if !allowed? do
    ┃             raise "Not allowed!"
    ┃           else
    ┃             proceed_as_planned
    ┃           end
    ┃
    ┃       ... should be refactored to look like this:
    ┃
    ┃           if allowed? do
    ┃             proceed_as_planned
    ┃           else
    ┃             raise "Not allowed!"
    ┃           end
    ┃
    ┃       The reason for this is not a technical but a human one. It is easier to wrap
    ┃       your head around a positive condition and then thinking "and else we do ...".
    ┃
    ┃       In the above example raising the error in case something is not allowed
    ┃       might seem so important to put it first. But when you revisit this code a
    ┃       while later or have to introduce a colleague to it, you might be surprised
    ┃       how much clearer things get when the "happy path" comes first.



## Configuration


### Configuration via .credo.exs

Credo is configured via a file called `.credo.exs`. This file can live in your project's `config/` or root folder, both is fine.

This also works for umbrella projects, where you can have individual `.credo.exs` files for each app or a global one in the umbrella's `config/` or root folder.

```elixir
# config/.credo.exs
%{
  configs: [
    %{
      name: "default",
      files: %{
        included: ["lib/", "src/", "web/", "apps/"],
        excluded: []
      },
      checks: [
        {Credo.Check.Consistency.TabsOrSpaces},

        # For some checks, like AliasUsage, you can only customize the priority
        # Priority values are: `low, normal, high, higher`
        {Credo.Check.Design.AliasUsage, priority: :low},

        # For others you can also set parameters
        {Credo.Check.Readability.MaxLineLength, priority: :low, max_length: 80},

        # You can also customize the exit_status of each check.
        # If you don't want TODO comments to cause `mix credo` to fail, just
        # set this value to 0 (zero).
        {Credo.Check.Design.TagTODO, exit_status: 2},

        # To deactivate a check:
        # Put `false` as second element:
        {Credo.Check.Design.TagFIXME, false},

        # ... several checks omitted for readability ...
      ]
    }
  ]
}
```

`mix credo --config-name <NAME_OF_CONFIG>` allows you to use a specific config (instead of `default`) inside a config file.

`mix credo --config-file <PATH_TO_CONFIG_FILE>` let's you use a specific config file.

Finally, you can use `mix credo gen.config` to generate a complete example configuration.


### Inline Configuration via Config Comments

Users of Credo can now disable individual lines or files for all or just
specific checks.

```elixir
defp do_stuff() do
  # credo:disable-for-next-line
  IO.inspect {:we_want_this_inspect_in_production!}
end
```

There are four config comments:

* `# credo:disable-for-this-file` - to disable for the entire file
* `# credo:disable-for-next-line` - to disable for the next line
* `# credo:disable-for-previous-line` - to disable for the previous line
* `# credo:disable-for-lines:<count>` - to disable for the given number of lines (negative for previous lines)

Each of these can also take the name of the check you want to disable:

```elixir
defp my_fun() do
  # credo:disable-for-next-line Credo.Check.Warning.IoInspect
  IO.inspect {:we_want_this_inspect_in_production!}
end
```

Lastly, you can put a regular expression (`/.+/`) instead of a check name to disable multiple checks (or if you do not want to type out the checks):

```elixir
defp my_fun() do
  # credo:disable-for-next-line /\.Warning\./
  IO.inspect {:we_want_this_inspect_in_production!}
end
```


## Exit Status

Credo fails with an exit status != 0 if it shows any issues. This enables shell based pipeline workflows (e.g. on CI systems) which test Credo compliance.

The exit status of each check is used to construct a bit map of the types of
issues which were encountered by or-ing them together to produce the final
result:

```elixir
use Bitwise

issues
|> Enum.map(&(&1.exit_status))
|> Enum.reduce(0, &(&1 ||| &2))
```

This way you can reason about the encountered issues right from the exit status.

Default values for the checks are based on their category:

    consistency:  1
    design:       2
    readability:  4
    refactor:     8
    warning:     16

So an exit status of 12 tells you that you have only Readability Issues and Refactoring Opportunities, but e.g. no Warnings.


## Commands

### suggest (default command)

`suggest` is the default command of Credo. It suggests issues to fix in your code, but it cuts the list to a digestable count. If you want to see the full list, use the `--all`  switch.

Example usage:

    $ mix credo                         # display standard report
    $ mix credo suggest                 # same thing, since it's the default command
    $ mix credo --all --format=json     # include low priority issues, output as JSON

    $ mix credo suggest --help          # more options


### list

`list` also suggests issues, but it groups them by file and does NOT cut the list to a certain count.

Example usage:

    $ mix credo list                      # show issues grouped by file
    $ mix credo list --format=oneline     # show issues grouped by file, one issue per line
    $ mix credo list --format=oneline -a  # same thing, include low priority issues

    $ mix credo list --help               # more options


### explain

`explain` allows you to dig deeper into an issue, by showing you details about the issue and the reasoning by it being reported. To be convenient, you can just copy-paste the `filename:line_number:column` string from the report behind the Credo command to check it out.

*Credits:* This is inspired by how you can snap the info from failed tests behind `mix test`.

Example usage:

    $ mix credo lib/my_app/server.ex:10:24          # show explanation for the issue
    $ mix credo explain lib/my_app/server.ex:10:24  # same thing

There are no additional options.



### categories

`categories` shows you all issue categories and explains their semantics.

There are no additional options.


### info

`info` shows you information relevant to investigating errors and submitting bug reports.

Example usage:

    $ mix credo info
    $ mix credo info --verbose
    $ mix credo info --verbose --format=json

## Command line options


### Output Formats

Use `--format` to format the output in one of the following formats:

- `--format=flycheck` for [Flycheck](http://www.flycheck.org/) output
- `--format=json` for [JSON](https://www.json.org/) output


### Only run some checks

To run only a subset of checks, you can use the `--checks` or the `-c` alias (also aliased as `--only`).

```bash
# to only run the Readability checks, use:

$ mix credo --only readability

# to only run Readability checks and Warnings, use:

$ mix credo --only readability,warning
```

The second example illustrates how the command takes a comma-separated list. All commands matching **any** of the passed items will be run.

You can use partial names to quickly run checks. `mix credo --only todo` will show all `# TODO` comments since `todo` will match Credo.Check.Design.Tag**TODO**. `mix credo --only inspect` will show you all calls to `IO.inspect` since it matches Credo.Check.Warning.Io**Inspect**.


### Ignore some checks

To ignore selected checks, you can use the `--ignore-checks` or the `-i` alias (also aliased as `--ignore`).

```bash
# to ignore all Readability checks, use:

$ mix credo --ignore readability

# to ignore all Readability checks and the DuplicatedCode check, use:

$ mix credo --ignore readability,duplicated
```

The second example illustrates how the command takes a comma-separated list. All commands matching any of the passed items will be ignored.

You can use partial names to quickly exclude checks. `mix credo --ignore nameredec` will exclude all checks for variables/parameters having the same name as declared functions by matching Credo.Check.Warning.**NameRedeclarationBy...**


### Parsing source from STDIN

You can also use Credo to parse source that has been piped directly into it.
This is especially useful when integrating with external editors. You can use this feature by passing the `--read-from-stdin` option as follows:

```bash
$ echo 'IO.puts("hello world");' | mix credo --format=flycheck --read-from-stdin
# stdin:1: C: There is no whitespace around parentheses/brackets most of the time, but here there is.
```

Notice the origin if the source is coming annotated as `stdin`, you can change this annotation by passing it along after option like so:

```bash
$ echo 'IO.puts("hello world");' | mix credo --format=flycheck --read-from-stdin /path/representing/the_current/source.ex
# /path/representing/the_current/source.ex:1: C: There is no whitespace around parentheses/brackets most of the time, but here there is.
```

Do note with the passed option as filename is a stub that is just used to prefix the error and so certain editors can annotate the original file.


### Using Credo as stand alone

If you do not want or are not allowed to include Credo in the current project you can also install it as an archive. For this, you also need to install [bunt](https://github.com/rrrene/bunt):

```bash
git clone git@github.com:rrrene/bunt.git
cd bunt
mix archive.build
mix archive.install
cd -
git clone git@github.com:rrrene/credo.git
cd credo
mix deps.get
mix archive.build
mix archive.install
```

**Important:** You have to install `bunt` as well:

```bash
git clone https://github.com/rrrene/bunt
cd bunt
mix archive.build
mix archive.install
```

You will now be able to invoke credo as usual through Mix with `mix credo`. This option is especially handy so credo can be used by external editors.


### Show code snippets in the output

Use the `--verbose` switch to include the code snippets in question in the output.


### Show all issues including low priority ones

Use the `--all-priorities` switch to include low priority issues in the output (aliased as `--strict`).


## Issues

Like any code linter, Credo reports issues. Contrary to many other linters these issues are not created equal. Each issue is assigned a priority, based on a base priority set by the config and a dynamic component based on violation severity and location in the source code.

These priorities hint at the importance of each issue and are displayed in the command-line interface using arrows: ↑ ↗ → ↘ ↓

By default, only issues with a positive priority are part of the report (↑ ↗ →).



## Checks


### Consistency

These checks take a look at your code and ensure a consistent coding style. Using tabs or spaces? Both is fine, just don't mix them or Credo will tell you.


### Readability

Readability checks do not concern themselves with the technical correctness of your code, but how easy it is to digest.


### Refactoring Opportunities

The Refactor checks show you opportunities to avoid future problems and technical debt.


### Software Design

While refactor checks show you possible problems, these checks try to highlight possibilities, like - potentially intended - duplicated code or `TODO:` and `FIXME` annotations.


### Warnings

These checks warn you about things that are potentially dangerous, like a missed call to `IEx.pry` or a call to `String.downcase` without saving the result.

## Plugins

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

## Integrations

### IDE/Editor

Some IDEs and editors are able to run Credo in the background and mark issues inline.

* [IntelliJ Elixir](https://github.com/KronicDeth/intellij-elixir#credo) - Elixir plugin for JetBrains IDEs (IntelliJ IDEA, Rubymine, PHPStorm, PyCharm, etc)
* [linter-elixir-credo](https://atom.io/packages/linter-elixir-credo) - Package for Atom editor (by @smeevil)

### Automated Code Review

* [Codacy](https://www.codacy.com/) - checks your code from style to security, duplication, complexity, and also integrates with coverage.
* [Stickler CI](https://stickler-ci.com/) - checks your code for style and best practices across your entire stack.

## Contributing

1. [Fork it!](http://github.com/rrrene/credo/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request



## Author

René Föhring (@rrrene)



## License

Credo is released under the MIT License. See the LICENSE file for further
details.
