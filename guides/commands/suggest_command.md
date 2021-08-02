# mix credo suggest

`suggest` suggests issues to fix in your code.

## Examples

```bash
$ mix credo
$ mix credo suggest                 # same thing, since it's the default command
$ mix credo --strict --format=json  # include low priority issues, output as JSON
$ mix credo suggest --help          # more options

$ mix credo suggest --format json
$ mix credo suggest lib/**/*.ex --only consistency --strict
$ mix credo suggest --checks-without-tag formatter --checks-without-tag controversial
```

## Command Line Switches

| Name, shorthand   | Description  |
|-------------------|-----------------------------------------------------------------------------------|
| [`--all`](#all), [`-a`](#all) | Show all issues for each category |
| [`--all-priorities`](#all-priorities-aliased-as-strict), [`-A`](#all-priorities-aliased-as-strict) | Show all issues including low priority ones |
| [`--checks`](#checks-aliased-as-only) | Only include checks that match the given comma-seperated patterns |
| [`--checks-with-tag`](#checks-with-tag) | Only include checks that match the given tag |
| [`--checks-without-tag`](#checks-without-tag) | Ignore checks that match the given tag |
| [`--config-file`](#config-file) | Use the given config file as Credo's config |
| [`--config-name`](#config-name) | Use the given config instead of "default" |
| [`--enable-disabled-checks`](#enable-disabled-checks) | Re-enable disabled checks that match the given comma-seperated patterns |
| [`--files-included`](#files-included) | Only include these files |
| [`--files-excluded`](#files-excluded) | Exclude these files |
| [`--format`](#format) | Display the list in a specific format (json, flycheck, or oneline) |
| [`--ignore-checks`](#ignore-checks-aliased-as-ignore) | Ignore checks that match the given comma-seperated patterns |
| [`--ignore`](#ignore) | Alias for [`--ignore-checks`](#ignore-checks-aliased-as-ignore) |
| [`--min-priority`](#min-priority) | Minimum priority to show issues |
| [`--mute-exit-status`](#mute-exit-status) | Exit with status zero even if there are issues |
| [`--only`](#only) | Alias for [`--checks`](#checks-aliased-as-only) |
| [`--strict`](#strict) | Alias for [`--all-priorities`](#all-priorities-aliased-as-strict) |
| [`--verbose`](#verbose) | Additionally print the check and the source code that raised the issue |

## Descriptions

### `--all`

Show all issues for each category

By default, Credo's report is limited to 5 issues per category.

```bash
$ mix credo --all
```

### `--all-priorities` (aliased as `--strict`)

Show all issues including low priority ones

By default, Credo's report is limited to high priority issues as indicated by the arrows (↑ ↗ → ↘ ↓) next to each issue.

```bash
$ mix credo --strict
```

### `--checks` (aliased as `--only`)

Only include checks that match the given comma-seperated patterns

```bash
# Run only checks where the name matches "readability" or "space" (case-insensitive),
# e.g. `Credo.Check.Readability.ModuleDoc` or `Credo.Check.Consistency.SpaceAroundOperators`
$ mix credo --only readability,space
```

The patterns are also compiled using `Regex.compile/2`, which allows for more complex queries:

```bash
# Run only checks where the name matches "readability" and "space"
# (case-insensitive), e.g. `Credo.Check.Readability.SpaceAfterCommas`
$ mix credo --only readability.+space
```

### `--checks-with-tag`

Only include checks that match the given tag (can be used multiple times)

```bash
$ mix credo --checks-with-tag experimental --checks-with-tag controversial
```

### `--checks-without-tag`

Ignore checks that match the given tag (can be used multiple times)

```bash
$ mix credo --checks-without-tag formatter
```

### `--config-file`

Use the given config file as Credo's config

```bash
$ mix credo --config-file ./path/to/credo.exs
```

This disables [Transitive configuration files](config_file.html#transitive-configuration-files) and only the given config file is

### `--config-name`

Use the given config instead of "default"

```bash
$ mix credo --config-name special-ci-config
```

### `--enable-disabled-checks`

Re-enable disabled checks that match the given comma-seperated patterns

```bash
# Enable all disabled checks where the name matches "readability" or "space" (case-insensitive),
# e.g. `Credo.Check.Readability.ModuleDoc` or `Credo.Check.Consistency.SpaceAroundOperators`
$ mix credo --enable-disabled-checks readability,space
```

The patterns are also compiled using `Regex.compile/2`, which allows for more complex queries:

```bash
# Enable all previously disabled checks where the name matches "readability" and "space"
# (case-insensitive), e.g. `Credo.Check.Readability.SpaceAfterCommas`
$ mix credo --enable-disabled-checks readability.+space

# Enable *all* disabled checks by simply using:
$ mix credo --enable-disabled-checks .+
```

### `--files-included`

Only include these files (accepts globs, can be used multiple times)

```bash
$ mix credo --files-included "./lib/**/*.ex" --files-included "./src/**/*.ex"
```

### `--files-excluded`

Exclude these files (accepts globs, can be used multiple times)

```bash
$ mix credo --files-excluded "./test/**/*.exs"
```

### `--format`

Display the list in a specific format (json, flycheck, or oneline)

```bash
$ mix credo --format json
```

### `--ignore-checks` (aliased as `--ignore`)

Ignore checks that match the given comma-seperated patterns

```bash
# Ignore checks where the name matches "readability" or "space" (case-insensitive),
# e.g. `Credo.Check.Readability.ModuleDoc` or `Credo.Check.Consistency.SpaceAroundOperators`
$ mix credo --ignore readability,space
```

The patterns are also compiled using `Regex.compile/2`, which allows for more complex queries:

```bash
# Ignore checks where the name matches "readability" and "space"
# (case-insensitive), e.g. `Credo.Check.Readability.SpaceAfterCommas`
$ mix credo --ignore readability.+space
```

### `--ignore`

Alias for [`--ignore-checks`](#ignore-checks-aliased-as-ignore)

### `--min-priority`

Minimum priority to show issues (high,medium,normal,low,lower or number)

```bash
$ mix credo --min-priority high
```

### `--mute-exit-status`

Exit with status zero even if there are issues

```bash
$ mix credo --format json
# ...

$ echo $?
0
```

### `--only`

Alias for [`--checks`](#checks-aliased-as-only)

### `--strict`

Alias for [`--all-priorities`](#all-priorities-aliased-as-strict)

### `--verbose`

Additionally print the check and the source code that raised the issue

```bash
$ mix credo --verbose

# ...

┃
┃ [W] ↗ There should be no calls to IO.inspect/1. [Credo.Check.Warning.IoInspect]
┃       lib/foo/bar.ex:121:6 #(Foo.Bar.run)
┃
┃       |> IO.inspect(label: "Arguments given")
┃          ^^^^^^^^^^
┃
```
