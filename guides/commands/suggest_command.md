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

The available command line switches are:

- [`--all`](#all)
- [`--all-priorities`](#all-priorities-aliased-as-strict)
- [`--checks`](#checks-aliased-as-only)
- [`--checks-with-tag`](#checks-with-tag)
- [`--checks-without-tag`](#checks-without-tag)
- [`--config-file`](#config-file)
- [`--config-name`](#config-name)
- [`--enable-disabled-checks`](#enable-disabled-checks)
- [`--files-included`](#files-included)
- [`--files-excluded`](#files-excluded)
- [`--format`](#format)
- [`--ignore-checks`](#ignore-checks-aliased-as-ignore)
- [`--ignore`](#ignore)
- [`--min-priority`](#min-priority)
- [`--mute-exit-status`](#mute-exit-status)
- [`--only`](#only)
- [`--strict`](#strict)

### `--all`

Shows all issues for each category.

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

Only include checks that match the given strings

```bash
# Runs only checks where the name matches "readability" (case-insensitive), e.g. `Credo.Check.Readability.ModuleDoc`
$ mix credo --only readability
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

Use the given config file as Credo's config.

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

Re-enable disabled checks that match the given strings

```bash
# Enable all previously disabled checks where the name matches "readability"
# (case-insensitive), e.g. `Credo.Check.Readability.ModuleDoc`
$ mix credo --enable-disabled-checks readability
```

### `--files-included`

Only include these files (accepts globs, can be used multiple times)

```bash
$ mix credo --files-included ./lib/**/*.ex --files-included ./src/**/*.ex
```

### `--files-excluded`

Exclude these files (accepts globs, can be used multiple times)

```bash
$ mix credo --files-excluded ./test/**/*.exs
```

### `--format`

Display the list in a specific format (json,flycheck,oneline)

```bash
$ mix credo --format json
```

### `--ignore-checks` (aliased as `--ignore`)

Ignore checks that match the given strings

```bash
# Ignore checks where the name matches "readability" (case-insensitive), e.g. `Credo.Check.Readability.ModuleDoc`
$ mix credo --ignore readability
```

### `--ignore`

Alias for --ignore-checks

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
