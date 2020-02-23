# CLI switches

Most configuration options are also available as command line switches.

```shell
➜ mix credo suggest --help
Usage: mix credo suggest [paths] [options]

Suggests objects from every category that Credo thinks can be improved.

Example: $ mix credo suggest lib/**/*.ex --all -c names

Arrows (↑ ↗ → ↘ ↓) hint at the importance of an issue.

Suggest options:
  -a, --all                     Show all issues
  -A, --all-priorities          Show all issues including low priority ones
  -c, --checks                  Only include checks that match the given strings
      --config-file             Use the given config file
  -C, --config-name             Use the given config instead of "default"
      --enable-disabled-checks  Re-enable disabled checks that match the given strings
      --files-included          Only include these files (accepts globs, can be used multiple times)
      --files-excluded          Exclude these files (accepts globs, can be used multiple times)
      --format                  Display the list in a specific format (json,flycheck,oneline)
  -i, --ignore-checks           Ignore checks that match the given strings
      --min-priority            Minimum priority to show issues (high,medium,normal,low,lower or number)
      --mute-exit-status        Exit with status zero even if there are issues

General options:
      --[no-]color        Toggle colored output
  -v, --version           Show version
  -h, --help              Show this help
```

Some of these are not available as options in `.credo.exs`:

* `--ignore-checks [PATTERN]` allows you to ignore some checks on-the-fly
* `--checks [PATTERN]` allows you to only run some checks
* `--enable-disabled-checks [PATTERN]` activates disabled checks on the fly
* `--format [FORMAT]`
* `--mute-exit-status` forces Credo to exit with an exit status of `0`

In all check-related switches, `PATTERN` is a comma-delimted list of patterns:

```shell
$ mix credo info --enable-disabled-checks Credo.Check.Readability.Specs,Credo.Check.Refactor.DoubleBooleanNegation
```

Of course, you can have the same effect by choosing the pattern less explicitly:

```shell
$ mix credo info --enable-disabled-checks specs,double
```
