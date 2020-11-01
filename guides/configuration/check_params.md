# Check Parameters

## Configuration

Checks are configured in [Credo's configuration file](config_file.html):

```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      checks: [
        {Credo.Check.Consistency.TabsOrSpaces, false},
        {Credo.Check.Design.AliasUsage, if_nested_deeper_than: 2},
      ],
      # files etc.
    }
  ]
}
```

All checks are configured using a two-element tuple:

```elixir
{MyApp.CheckModule, params}
```

`MyApp.CheckModule` is the module representing the check to be configured ([read more about custom checks](adding_checks.html)).

`params` can be either `false`, to disable the check ...

```elixir
# This check won't be part of the analysis
{Credo.Check.Consistency.TabsOrSpaces, false}
```

... or a keyword list of parameters, used to configure the check:

```elixir
{Credo.Check.Design.AliasUsage, if_nested_deeper_than: 2}
```

## General params

While `params` are defined by each check individually, there are a couple of general params provided by Credo, which work the same for each check.

The general params available are:

- [`:category`](#category)
- [`:exit_status`](#exit_status)
- [`:files`](#files)
- [`:priority`](#priority)
- [`:tags`](#tags)

### `:category`

Overwrites the category of the check

```elixir
{Credo.Check.Warning.IExPry, category: :readability}
```

### `:exit_status`

Overwrites a custom exit status for the check

```elixir
{Credo.Check.Warning.IoInspect, exit_status: 0}
```

### `:files`

Controls which files the check runs on.

This allows for specific files or patterns to be included/excluded for specific checks.

The syntax is the same as for the top-level `:files` key:

```elixir
# check included for Elixir files in lib/ only
{Credo.Check.Consistency.ExceptionNames, files: %{included: ["lib/**/*.ex"]}},

# check excluded for a specific file
{Credo.Check.Warning.IExPry, files: %{excluded: ["lib/debug_server.ex"]}},

# check included for all Elixir script files, but excluded for test scripts
{Credo.Check.Warning.IoInspect, files: %{included: ["**/*.exs"], excluded: ["**/*_test.exs"]}},
```

Please note that these params do not "override" the top-level config, but are applied to the result of the top-level config's resolution.

### `:priority`

Overwrites the priority of the check

### `:tags`

Overwrites or appends the tags of the check

```elixir
# Overwrite all tags for `MyApp.CheckModule`
{MyApp.CheckModule, tags: [:my_tag]}

# OR: append tags to `MyApp.CheckModule`
{MyApp.CheckModule, tags: [:__initial__, :my_tag]}
```

Tags can then be used as usual, via the CLI switch `--checks-with[out]-tag`:

```bash
# Only run checks tagged `:my_tag` during analysis
$ mix credo --checks-with-tag my_tag

# Exclude all checks tagged `:my_tag` from analysis
$ mix credo --checks-without-tag my_tag
```
