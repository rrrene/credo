# Command line switches

Most configuration options are also available as command line switches, so that you can e.g. only run certain checks at a time to focus attention on those issues.

## Common use cases

Here are a couple of common use case and their respective command line switches:

### Output Formats

Use `--format` to format the output in one of the following formats:

- `--format flycheck` for [Flycheck](http://www.flycheck.org/) output
- `--format json` for [JSON](https://www.json.org/) output


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

### Show all issues including low priority ones

Use the `--all-priorities` switch to include low priority issues in the output (aliased as `--strict`).

## Command line switches and config file

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

* `--enable-disabled-checks [PATTERN]` activates disabled checks on the fly
* `--mute-exit-status` forces Credo to exit with an exit status of `0`

In all check-related switches, `PATTERN` is a comma-delimted list of case-insensitive patterns:

```shell
$ mix credo info --enable-disabled-checks Credo.Check.Readability.Specs,Credo.Check.Refactor.DoubleBooleanNegation
```

Of course, you can have the same effect by choosing the pattern less explicitly:

```shell
$ mix credo info --enable-disabled-checks specs,double
```

