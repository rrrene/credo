# Configuration


## Configuration via .credo.exs

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


## Inline Configuration via Config Comments

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
