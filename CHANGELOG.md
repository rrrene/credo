# Changelog

## 1.7.12

- Fix compatibility & compiler warnings with Elixir 1.19 (dev)
- Provide `:column` on all checks
- Fix check docs in other project's documentation
- `Credo.Check.Refactor.DoubleBooleanNegation` fixed false positive
- `Credo.Check.Readability.NestedFunctionCalls` fixed false positive
- `Credo.Check.Consistency.UnusedVariableNames` fixed duplicate issues

## 1.7.11

- Fix compatibility & compiler warnings with Elixir 1.18
- Fix crashing for invalid strings in issue messages
- Show required Elixir version for skipped checks
- Add options `:exit_status` and `:category` to `format_issue/2` when using `Credo.Check`
- `Credo.Check.Readability.ModuleDoc` fixed false positive
- `Credo.Check.Warning.UnusedEnumOperation` fixed false positive
- `Credo.Check.Refactor.ABCSize` fixed false positive for tuples and underscored matches (`_foo`)

## 1.7.10

- Maintenance release

## 1.7.9

- `Credo.Check.Refactor.ABCSize` fixed false positive for pin operator (`^`)
- `Credo.Check.Readability.FunctionNames` fixed false positive for pow operator (`**`)
- Fixed a bug in `Credo.Code.Parameters` when couting parameters for functions with guards

## 1.7.8

- `Credo.Check.Refactor.Apply` fixed false positive
- `Credo.Check.Warning.IoInspect` fixed false positive
- `Credo.Check.Warning.UnsafeToAtom` fixed false positive
- `Credo.Check.Readability.FunctionNames` fixed false positive

## 1.7.7

- Fix compatibility & compiler warnings with Elixir 1.17
- `Credo.Check.Design.SkipTestWithoutComment`, `Credo.Check.Refactor.PassAsyncInTestCases` and `Credo.Check.Warning.WrongTestFileExtension` now work for umbrella apps

## 1.7.6

- `Credo.Check.Consistency.MultiAliasImportRequireUse` fixed false positive
- `Credo.Check.Readability.PredicateFunctionNames` now ignores functions that implement a behaviour
- `Credo.Check.Readability.FunctionName` now supports multi-letter sigils
- `Credo.Check.Readability.Specs` fixed false positive
- `Credo.Check.Warning.UnusedKeywordOperation` fixed false positive
- Fix `column` information on several checks in case there are two offending calls on the same line
- Fix some deprecation warnings for upcoming Elixir 1.17

## 1.7.5

- Fix `--read-from-stdin` not respecting `:files`/`:included` param
- `Credo.Check.Readability.NestedFunctionCalls` no longer crashes for functions with an unquoted name

## 1.7.4

- Add new check `Credo.Check.Refactor.UtcNowTruncate` as opt-in check (this is scheduled to become a standard check in v1.8)
- Add lots of improvements around `:trigger` in `Credo.Issue`
- Add new output format `short`
- Improve docs for several checks
- Fix another, smaller bottleneck in multicore performance
- Fix `--read-from-stdin` not respecting `:files` param
- Fix SARIF output format for non-string triggers
- Fix initializing builtin commands twice
- Fix `diff` command not recognizing a git ref as first argument

## 1.7.3

- `Credo.Check.Readability.AliasOrder` now supports a `:sort_method` parameter
- `Credo.Check.Readability.PredicateFunctionNames` received fixes
- `Credo.Check.Warning.MissedMetadataKeyInLoggerConfig` received fixes

## 1.7.2

- Fix compatibility & compiler warnings with Elixir 1.16
- Fix a bottleneck in multicore performance
- Cache scope priorities
- `CHANGELOG.md` is now included in the package
- `Credo.Check.Readability.NestedFunctionCalls` no longer warns on function calls in interpolated strings
- `Credo.Check.Readability.PredicateFunctionNames` fixed false positives
- `Credo.Check.Readability.RedundantBlankLines` fixed a bug with double quotes multiline strings
- `Credo.Check.Refactor.ModuleDependencies` now takes modules for `:excluded_namespaces` parameter
- `Credo.Check.Refactor.NegatedIsNil` no longer leaks memory
- `Credo.Check.Warning.Dbg` now warns when part of a pipeline and called without parens
- `Credo.Check.Warning.MissedMetadataKeyInLoggerConfig` received various fixes and improvements

## 1.7.1

- Fix compatibility & compiler warnings with Elixir 1.15
- Improve docs
- `Credo.Check.Readability.Specs` works for parensless definitions

## 1.7.0

- `Credo.Check.Readability.ModuleDoc` works for Phoenix 1.7+ views
- `Credo.Check.Readability.FunctionNames` now ignores custom operators
- `Credo.Check.Refactor.Apply` now works in pipes
- `Credo.Check.Consistency.ExceptionNames` does no longer yield an issue if there is only one match
- `Credo.Check.Readability.ModuleNames` now supports an `:ignore` parameter
- `Credo.Check.Design.AliasUsage` now supports an `:if_referenced` parameter
- `Credo.Check.Readability.FunctionNames` now works for acronyms in predicate functions
- `Credo.Check.Readability.NestedFunctionCalls` now works for calls already in a pipeline and local function calls

### Add SARIF support

Credo 1.7 provides a formatter that will output data in [SARIF](http://sarifweb.azurewebsites.net) format, allowing [direct GitHub support](https://help.github.com/en/github/finding-security-vulnerabilities-and-errors-in-your-code/uploading-a-sarif-file-to-github) via the `Security` tab.

You can now use `mix credo --format=sarif` to output results in SARIF format.

### Add IDs to checks

This was requested for SARIF support and has been added to provide a unique identifier for checks that is more technical than the check name.

Check authors can add IDs to their custom checks by using the `:id` option:

    defmodule MyCheck do
      use Credo.Check,
        id: "EX5042",
        category: :warning,
        # ...
    end

Credo's naming scheme for these IDs is simple:

```
EX5042
^^
```

`EX` stands for Elixir.

```
EX5042
  ^
```

The first digit represents the category.

```
EX5042
   ^
```

The second digit is always `0` for Credo's standard checks (see below).

```
EX5042
    ^^
```

The last two digits are the incremental number of the check.

This means that you can extend Credo with

* up to 99 categories,
* up to 999 checks per category or
* use the second digit for something completely different

all while adhering to Credo's own scheme (and of course, you can simply invent a completely different naming scheme for your checks).

### Allow passing of multiple files to Mix task

It is now possible to pass a list of files to `mix credo`.

```
mix credo lib/foo.ex lib/foo/bar.ex lib/foo/baz.ex
```

This means that you can now use the output of commands to determine which files to analyse, e.g.:

```
mix credo $(git diff --name-only)
```

### Ensure stable ordering of analysis results

Continuing our quest to remove ambiguity and reduce undocumented behaviour, Credo now orders its results by default.

Credo's results always had one caveat: Their order was determined by the runtime behaviour of the checks and workers running the checks (it was up to the output mechanism to provide its own stable order).

Now, results are always sorted by check ID, filename and line number.

### New checks

- `Credo.Check.Readability.OneArityFunctionInPipe`
- `Credo.Check.Readability.OnePipePerLine`
- `Credo.Check.Refactor.FilterCount`
- `Credo.Check.Refactor.PassAsyncInTestCases`
- `Credo.Check.Warning.MissedMetadataKeyInLoggerConfig`

## 1.6.7

- Improve compatibility with Elixir 1.14 (based on v1.14.0-rc.1)

## 1.6.6

- Fix error when analysing single-line modules
- Fix false positive for `Credo.Check.Readability.SpaceAroundOperators`
- Fix false positive for `Credo.Check.Warning.UnusedStringOperation`
- Fix bug in `Credo.Code.Scope.mod_name/1`

## 1.6.5

- Include the 'only_greater_than' value in the `Credo.Check.Readability.LargeNumbers` message
- Ignore Phoenix.LiveView modules by default
- Fix for false positive in `Credo.Check.Refactor.Apply`
- Fix for false positive in `Credo.Check.Refactor.NegatedIsNil`
- Fix for false positive in `Credo.Check.Readability.WithSingleClause`

## 1.6.4

- Fix for false positive in `Credo.Check.Readability.MaxLineLength`
- Fix a bug in `Credo.Check.Refactor.PipeChainStart`
- Fix error message in `gen.check` command

## 1.6.3

- The HTML report generated by `--debug` now includes slowest files, checks and file/check combinations
- Fix for false positive in `Credo.Check.Consistency.UnusedVariableNames`
- Fix for false positive in `Credo.Check.Readability.SpaceAfterCommas`
- Fix a bug in `Credo.Check.Warning.ForbiddenModule`
- Fix a bug in `Credo.Check.Warning.MixEnv`
- `Credo.Check.Readability.LargeNumbers` now supports `:trailing_digits`

## 1.6.2

- Bug fixes
- Add `-i` as shorthand for `--ignore`

## 1.6.1

- Improve compatibility with Elixir 1.13 (based on v1.13.0-rc.1)

## 1.6.0

- Credo changes from supporting the last 5 minor Elixir versions to the last 6, to be compatible with [Elixir's own support policy regarding bug fixes and security patches](https://hexdocs.pm/elixir/1.12/compatibility-and-deprecations.html)
- Credo's docs now provide the ability to link specific check params, e.g. [check out :max_length for MaxLineLength](Credo.Check.Readability.MaxLineLength.html#module-max_length)
- `Credo.Check.Readability.SinglePipe` now supports `:allow_0_arity_functions`
- `Credo.Check.Design.AliasUsage` now supports `:only`
- Credo now fails with an error message if a plugin module can not be initialized
- Prepare compatibility with Elixir 1.13

### First Run Mode

Credo 1.6 features a new mode, designed to be run every time you introduce Credo to an existing codebase.

```bash
mix credo --first-run
```

This offers a couple of suggestions on how to introduce Credo to your workflow/CI.

All of these suggestions are contextualized and project-specific, here's an example when running it on Credo's codebase:

```bash
-------------------------------------- 8< --------------------------------------


# Where to start?

That's a lot of issues to deal with at once.

While not recommended, you could simply start ignoring issues for the time being:

    mix credo --ignore readability      # exclude checks matching a given phrase

You can use `diff` to only show the issues that were introduced on this branch:

    mix credo diff master


## Compare to a point in history

Alternatively, you can use `diff` to only show the issues that were introduced after
a certain tag or commit:

    mix credo diff v1.5.6               # use the latest tag

    mix credo diff e0d84ba9             # use the current HEAD of master

Lastly, you can compare your working dir against this point in time:

    mix credo diff --since 2021-08-28   # use the current date


## Every project is different

Introducing code analysis to an existing codebase should not be about following any
"best practice" in particular, it should be about helping you to get to know the ropes
and make the changes you want.

Try the options outlined above to see which one is working for this project!
```

### New Diff Options

`mix credo diff` is often used when developing on a branch and comparing that branch with a base branch.

Let's illustrate this with the following example:

```text
(feature-a)                        J---K---L
                                  /         \
(master)          base---A---B---C---D---E---F
                              \
(current branch)               X---Y---Z
```

- `mix credo diff --from-git-ref master` (same as `mix credo diff master`) - this will compare the current branch to the current state of the given ref (commit `F` in the example above)
- `mix credo diff --from-git-merge-base master` - this will compare the current branch to the point where the current branch was branched off of the given ref (commit `B` in the example above)

There is also `--from-dir` which you can use to compare the current dir to another dir, thus decoupling the `diff` command from Git, e.g. `mix credo diff --from-dir ../credo_v1_5_6`

### Pinning Checks in a Project's Config

Credo's config always had one caveat: Your configuration settings are merged with the default config, without you having any chance of knowing what the default config is (except by generating a fresh one via `mix credo.gen.config`).

    %{
      configs: [
        %{
          name: "default",
          checks: [
            # this configures `LargeNumbers` and all default checks are still enabled
            {Credo.Check.Readability.LargeNumbers, only_greater_than: 99_999}
          ]
        }
      ]
    }

This adds an additional problem: When checks are added to the default config, they are also added for you, because there is no way to explicitly say, which checks should run.

Credo 1.6 adds this option to explicitly say which checks are enabled on your project by changing the `:checks` key in the config from a `List` to a `Map` with an `:enabled` key:

    %{
      configs: [
        %{
          name: "default",
          checks: %{
            enabled: [
              # this means that only `LargeNumbers` will run for this project
              {Credo.Check.Readability.LargeNumbers, only_greater_than: 99_999}
            ]
          }
        }
      ]
    }

You can now go the other way as well and disable checks explicitly while keeping their params instead of replacing them with `false`:

    %{
      configs: [
        %{
          name: "default",
          checks: %{
            disabled: [
              # this means that `LargeNumbers` is disabled for this project
              {Credo.Check.Readability.LargeNumbers, only_greater_than: 99_999}
            ]
          }
        }
      ]
    }

This has the added benefit that, when re-enabled via [`--enable-disabled-checks`](suggest_command.html#enable-disabled-checks), the check is enabled with its customized params.

[Credo configs are transitive](config_file.html#transitive-configuration-files) in nature, so what about a situation where you want to pin checks for an umbrella, but overwrite individual checks in a child app? You can use the `:extra` option:

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

Of course, the "old" way of specifying a list of checks still works.

### Exit Status

- Credo succeeds with an exit status of 0 (like any other program).
- Credo fails with an [exit status between 1 and 127](exit_statuses.html#issue-statuses) if it shows any issues.
- [Exit statuses above or equal to 128](exit_statuses.html#actual-custom-errors) indicate an Elixir runtime error during analysis itself.

Before Credo 1.6 it was unclear which exit status "ranges" where intended for which kind of error.
For example, we are not enforcing the ranges for issue errors or plugin errors, but this change gives an official guideline to these considerations.

### Working Directory

Up until now, Credo provided the ability to analyse files and directories anywhere on disk by simply typing

```bash
# BEFORE (now deprecated):
mix credo ../other-elixir-project/
```

This was not really documented and not really supported very well, resulting in most people not really utilizing it and instead running Credo from the root of their project using `mix credo`.

Now there is `--working-dir`, which allows users to define their working directory explicitly:

```bash
mix credo --working-dir ../other-elixir-project/
```

### New checks

- `Credo.Check.Design.SkipTestWithoutComment`
- `Credo.Check.Readability.PipeIntoAnonymousFunctions`
- `Credo.Check.Readability.SingleFunctionToBlockPipe`
- `Credo.Check.Refactor.Apply`
- `Credo.Check.Refactor.IoPuts`
- `Credo.Check.Refactor.MapJoin`
- `Credo.Check.Refactor.RedundantWithClauseResult`

## 1.5.6

- Ensure compatibility with Elixir 1.12

## 1.5.5

- Fix bug where compilation warnings are shown if compilation directory is not part of a Git work tree
- Fix bug in `mix credo diff` where too many issues are reported because

## 1.5.4

- Fix bug where `:exit_status` was not a valid option for `use Credo.Check`
- Fix bug where `mix credo diff` exited with a non-zero exit status even if no issues were shown
- `mix credo diff` now fails with an error if the given `ref` was not found

## 1.5.3

- Fix bug in `diff` and `version` command when `git` is not installed

## 1.5.2

- Fix output bug in `diff` command
- Fix bug in `diff` command when run on a Git ref that does not contain a given `--config-name`
- Fix bug in all commands when a given `--config-name` is not found
- Fix false positive in `Credo.Check.Warning.ExpensiveEmptyEnumCheck`
- Fix false positive in `Credo.Check.Refactor.PipeChainStart` regarding custom operators
- Fix `--version` to include pre version and build info for unpublished versions (e.g. when the dep is included via `path:` or `github:`)

## 1.5.1

- Fix bug in `diff` command when run on a subdirectory of a Git repository
- Fix bug in new general param `:files` when excluding files

## 1.5.0

- Credo now requires Elixir 1.7 or newer
- Refactor check runner (much faster now for common scenarios)
- Add param `allow_acronyms` to check `Credo.Check.Readability.FunctionNames`
- Add name of check to message when printing issues with `--verbose`
- Add support for "dynamic" tagging for checks via `.credo.exs`

      # Overwrite all tags for `FooCheck`
      {FooCheck, [tags: [:my_tag]]}

      # Add tags for `FooCheck`
      {SomeCredoCheck, [tags: [:__initial__, :my_tag]]}

  Tags can then be used as usual, via the CLI switch `--checks-with[out]-tag`:

      # Only run checks tagged `:my_tag` during analysis
      $ mix credo --checks-with-tag my_tag

      # Exclude all checks tagged `:my_tag` from analysis
      $ mix credo --checks-without-tag my_tag

### New switch to enable file watcher

You can now ask Credo to re-run on file changes:

      $ mix credo --watch

### New `diff` command

You can now ask Credo to only report changes in files that were changed since a given Git ref:

      $ mix credo diff HEAD^
      $ mix credo diff master

You can, of course, combine this with the new `--watch` switch to iteratively fix issues that have come up since the last release:

      $ mix credo diff v1.4.0 --watch

### New general check param `:files`

You can now include/exclude specific files or patterns for specific checks.

The syntax is the same as for the top-level `:files` key:

```elixir
# check included for Elixir files in lib/ only
{Credo.Check.Consistency.ExceptionNames, files: %{included: ["lib/**/*.ex"]}},

# check excluded for a specific file
{Credo.Check.Warning.IExPry, files: %{excluded: ["lib/debug_server.ex"]}},

# check included for all Elixir script files, but excluded for test scripts
{Credo.Check.Warning.IoInspect, files: %{included: ["**/*.exs"], excluded: ["**/*_test.exs"]}},
```

This means that you can now also include/exclude specific files or patterns for your custom checks **by default**.

The syntax is the same as with all other check params:

```elixir
defmodule MyApp.Check.SomethingAboutTests do
  use Credo.Check,
    base_priority: :normal,
    explanations: [
      check: """
      ...
      """
    ],
    param_defaults: [
      files: %{included: ["**/*_test.exs"]}
    ]
```

Please note that these params do not "override" the top-level config, but are applied to the result of the top-level config's resolution.

### New checks

These new checks can now be enabled:

- `Credo.Check.Readability.BlockPipe`
- `Credo.Check.Readability.ImplTrue`
- `Credo.Check.Readability.SeparateAliasRequire`

Additionally, `Credo.Check.Warning.ApplicationConfigInModuleAttribute` is a new check which warns about reading environment variables into module attributes at compile-time and is enabled by default.

## 1.4.1

- Ensure compatibility with Elixir 1.11.0

## 1.4.0

- Credo's schema for pre-release names changes: There is now a `.` after the `rc` like in many other Elixir projects.

- Add support for explaining checks (in addition to issues), i.e.

      $ mix credo explain Credo.Check.Design.AliasUsage

- Add support for tags on checks

  Checks can now declare tags via the `__using__` macro, i.e.

      defmodule MyCheck do
        use Credo.Check, tags: [:foo]

        def run(%SourceFile{} = source_file, params) do
          #
        end
      end

  Tags can be used via the CLI switch `--checks-with[out]-tag`:

      # Only run checks tagged `:foo` during analysis
      $ mix credo --checks-with-tag foo

      # Exclude all checks tagged `:foo` from analysis
      $ mix credo --checks-without-tag foo

- Add validation of check params in config

  If a param is not found, Credo checks for mispellings and suggests corrections:

      $ mix credo
      ** (config) Credo.Check.Design.AliasUsage: unknown param `fi_called_more_often_than`. Did you mean `if_called_more_often_than`?

- Add auto-generated check docs
- Add new documentation on Hex with [extra guides](https://hexdocs.pm/credo/1.4.0/overview.html) and [CHANGELOG](https://hexdocs.pm/credo/1.4.0/changelog.html)

## 1.3.2

- Support non-ascii characters in variable names
- Fix false positive in `Credo.Check.Readability.ParenthesesOnZeroArityDefs`

## 1.3.1

- Fix new check (`Credo.Check.Readability.StrictModuleLayout`)
- Ignore module attributes in UnsafeToAtom

## 1.3.0

- Enable `Credo.Check.Readability.UnnecessaryAliasExpansion` check by default
- Fix bugs when removing heredocs and charlists from sources
- Fix false positive on TrailingWhiteSpace
- Add `ignore: [:fun1, :fun2]` param to all `UnusedOperation*` checks; to ignore unused `Enum.reduce/3` operations, use

      {Credo.Check.Warning.UnusedEnumOperation, [ignore: [:reduce]]},

### New switch to re-enable disabled checks

Use `--enable-disabled-checks [pattern]` to re-enable checks that were disabled in the config using `{CheckModule, false}`. This comes in handy when using checks on a case-by-case basis

As with other check-related switches, `pattern` is a comma-delimted list of patterns:

    $ mix credo info --enable-disabled-checks Credo.Check.Readability.Specs,Credo.Check.Refactor.DoubleBooleanNegation

Of course, we can have the same effect by choosing the pattern less explicitly:

    $ mix credo info --enable-disabled-checks specs,double

### New API for custom checks

> This deprecates the mandatory use of `@explanation` and `@default_params` module attributes for checks.

Before `v1.3` you had to define module attributes named `@explanation` and `@default_params` before calling
`use Credo.Check`.

Now you can pass `:explanations` (plural) and `:param_defaults` options directly to `use Credo.Check`.

```elixir
defmodule MyCheck do
  use Credo.Check,
    category: :warning,
    base_priority: :high,
    param_defaults: [param1: 42, param2: "offline"],
    explanations: [
      check: "...",
      params: [
        param1: "Your favorite number",
        param2: "Online/Offline mode"
      ]
    ]

  def run(%SourceFile{} = source_file, params) do
    #
  end
end
```

Please note that these options
are also **just a convenience** to implement the functions specified by the  `Credo.Check` behaviour.
You can alternatively implement the respective functions yourself:

```elixir
defmodule MyCheck do
  use Credo.Check

  def category, do: :warning

  def base_priority, do: :high

  def explanations do
    [
      check: "...",
      params: [
        param1: "Your favorite number",
        param2: "Online/Offline mode"
      ]
    ]
  end

  def param_defaults, do: [param1: 42, param2: "offline"]

  def run(%SourceFile{} = source_file, params) do
    #
  end
end
```

### New checks

- `Credo.Check.Readability.StrictModuleLayout`
- `Credo.Check.Readability.WithCustomTaggedTuple`
- `Credo.Check.Warning.LeakyEnvironment`
- `Credo.Check.Warning.UnsafeExec`

## 1.2.3

- Fix performance bottleneck in `Credo.Service.ETSTableHelper`

## 1.2.2

- Fix token interpretation of Floats

## 1.2.1

- Actually enable the new check (`Credo.Check.Warning.MixEnv`)

## 1.2.0

- Commands can now have their own pipelines, so that plugins can extend them.
- Add pipelines to `SuggestCommand` and `ListCommand`
- `Credo.Plugin.append_task/4` and `Credo.Plugin.prepend_task/4` let you append/prepend tasks to Command's pipelines.
- Validate options given to `use Credo.Check`
- Fix `TrailingWhiteSpace` check on Windows
- Fix `MultiAlias` to work with submodule expansion
- Fix `UnusedVariableNames` bug
- Fix `Heredocs.replace_with_spaces/5` bug
- Fix `InterpolationHelper.replace_interpolations/2` bug
- Fix crash in `AliasAs` check when __MODULE__ is aliased
- Fix speed pitfall in `Scope.name/2`
- New config option: `parse_timeout`
- Improved default settings for umbrella apps

### New checks

- `Credo.Check.Warning.MixEnv`

## 1.1.5

- Add JSON output to `categories` and `explain` commands
- Include number of executed checks in summary
- Fix wrong trigger in `SinglePipe`

## 1.1.4

- Fix name parsing bug in `UnusedVariableNames`
- Fix bug when redefining operators in `FunctionNames`
- Fix false positive in `Specs`

## 1.1.3

- Improve warning message about skipped checks
- Fix false positive in `FunctionNames`
- Fix typespec in `IssueMeta`
- Add `AliasAs` check to list of optional checks

## 1.1.2

- Fix bug in `Heredocs` regarding indentation
- Fix bug in `FunctionNames` when using `unquote/1` in guards
- Fix bug in `FunctionNames` when defining `sigil_` functions for uppercase sigils

## 1.1.1

- Fix incompatibilities between Elixir 1.9, `Credo.Code.Token` and  `Credo.Code.InterpolationHelper`
- Fix error in `Heredocs` with certain UTF-8 chars
- New param for `ParenthesesOnZeroArityDefs`: use `[parens: true]` to force presence of parentheses on zero arity defs

## 1.1.0

- Credo now requires Elixir 1.5 and Erlang/OTP 19
- Fix false negative in `DuplicatedCode`
- `PipeChainStart` has been made opt-in

### Plugin Support

Credo now supports plugins that run alongside Credo's own analysis. While Credo provided the ability to write custom checks since `v0.4.0`, users can now access the complete toolset of Credo to create their own commands, require compilation, run external tools and still include the results in Credo's standard report.

Please refer to Credo's [README](https://github.com/rrrene/credo#plugins) as well as the [Credo Demo Plugin](https://github.com/rrrene/credo_demo_plugin) for further information on how to get started.

### New checks

- Credo.Check.Refactor.WithClauses

## 1.0.5

- Fix bug due to commented-out heredocs
- Fix variable explanation for `VariableRebinding` check
- Add `MultiAlias` check to experimental checks

## 1.0.4

- Ignore heredocs in `RedundantBlankLines`
- Fix bug in `StringSigils`
- Minor refactorings

## 1.0.3

- Fix bug in `Name.full/1`
- Fix bug in `UI.truncate/2`
- Disable `LazyLogging` for Elixir >= 1.7
- Add UnnecessaryAliasExpansion check to experimental checks

## 1.0.2

- Fix false positive in `MapInto`
- Disable `MapInto` for Elixir 1.8 and higher
- Ensure issues are sorted by filename, line number and column number
- Warn about ineffective check filter patterns
- Add `ModuleDependencies` check to experimental checks

## 1.0.1

- Compilation warnings for Elixir 1.8
- Fix `StringSigils` to not crash with strings containing non-UTF8 characters

## 1.0.0

- Improve documentation
- Add error handling for malformed config files
- Write all warnings to `:stderr`
- Fix false positive for charlists in PipeChainStart
- Remove deprecated --one-line switch
- Deactivate checks `DuplicatedCode` and `DoubleBooleanNegation` by default

### BREAKING CHANGES

These changes concern people writing their own checks for Credo.

- `Credo.Check.CodeHelper` was removed. Please use the corresponding functions inside the `Credo.Code` namespace.

## 0.10.2

- Fix bug in AliasOrder

## 0.10.1

- Fixed "unnecessary atom quotes" compiler warning during analysis
- Handle timeouts when reading source files
- Ignore function calls for OperationOnSameValues
- Do not treat `|>` as an operator in SpaceAroundOperators
- Fix AliasOrder bug for multi alias statements
- Fix multiple false positives for SpaceAroundOperators
- ... and lots of important little fixes to issue messages, docs and the like!

## 0.10.0

- Switch `poison` for `jason`
- Add command-line switch to load a custom configuration file (`--config-file`)
- Add a debug report in HTML format when running Credo using `--debug`
- Add `node_modules/` to default file excludes
- Add `:ignore_urls` param for MaxLineLength
- Report violation for `not` as well as `!` in Refactor.NegatedConditionWithElse
- Fix false positive on LargeNumbers
- Fix NegatedConditionWithElse for `not/2` as well
- Disable PreferUnquotedAtoms for Elixir >= 1.7.0

### New checks

- Credo.Check.Refactor.MapInto

## 0.9.3

- Fix bug in Scope
- Fix false positive in MatchInConditionTest
- Fix false positive in UnusedEnumOperation
- Fix custom tasks by resolving config before validating it
- Add text support to `--min-priority` CLI switch (you can now set it to low/normal/high)

### New checks

- Credo.Check.Readability.AliasOrder

## 0.9.2

- Add `:ignore_comments` param to LongQuoteBlocks
- Fix false positive in UnusedPathOperation

## 0.9.1

- Fix false positive in SpaceAroundOperators
- Fix false positive in UnusedEnumOperation

## 0.9.0

- Add JSON support
- Ensure compatibility with Elixir 1.6
- Format codebase using Elixir 1.6 Formatter
- Rework internals in preparation of 1.0 release
- Credo now requires Elixir 1.4
- Include `test` directory in default config
- Add `excluded_argument_types` to PipeChainStart
- Emit warnings for non-existing checks, which are referenced in config
- Improve VariableNames
- ModuleDoc now raises an issue for empty strings in @moduledoc tags
- Fix bug on ModuleNames
- Fix false positive in VariableRebinding
- Fix false positive in SpaceAroundOperators
- Fix false positive on BoolOperationOnSameValues
- Fix false positive on SpaceAfterCommas
- Fix false positive on MaxLineLength
- Fix false positive in ParenthesesInCondition
- Remove `NameRedeclarationBy*` checks
- Remove support for @lint attributes

## 0.8.10

- Maintenance release

## 0.8.9

- Fix false positive in ParenthesesInCondition
- Fix Code.to_tokens/1 for Elixir 1.6
- Fix documentation for several checks

### New checks

- Credo.Check.Warning.ExpensiveEmptyEnumCheck

## 0.8.8

- Fix false positive for `LargeNumbers`
- Fix `SpaceAroundOperators` for @type module attributes
- Ignore def arguments and specs for `OperationOnSameValues`
- Fix crash in `ParenthesesOnZeroArityDefs` for variables named `defp`
- Fix false positives for `TagHelper`

## 0.8.7

- Fix false positive in `ModuleAttributeNames`
- Fix false positives in unused return checks
- Fix underlining in "list" action
- Fix CLI argument parsing for `mix credo.gen.check`
- Fix loading of custom checks
- Prevent error when run against empty umbrella projects
- Prevent output for tests

## 0.8.6

- Fix false positive in SpaceAfterCommas
- Fix false positive in SpaceAroundOperators
- Fix bug with extracting explain command args
- Allow anonymous functions to be piped as raw values

## 0.8.5

- Speed up scope counting in CLI summary

## 0.8.4

- Remove `CheckForUpdates` for good
- Fix `RaiseInsideRescue` for implicit try

## 0.8.3

- Do not run `CheckForUpdates` on CI systems and in editor integrations

## 0.8.2

- Refactor all consistency checks, providing a nice speed improvement (thx @little-bobby-tables)
- Improve Elixir 1.5 compatibility

## 0.8.1

- Fix misleading issue message for `LongQuoteBlocks`

## 0.8.0

- Load source files in parallel
- Improve high memory consumption
- Fix comment handling of Charlists, Sigils and Strings
- `LazyLogging` now only checks for `debug` calls by default
- Add `--mute-exit-status` CLI switch, which mutes Credo's exit status (this will be used for integration tests as it means that any non-zero exit status results from a runtime error of Credo)
- Add default param values to `mix explain` output
- `TagTODO` and `TagFIXME` now also report tags from doc-related module attributes (`@doc`, `@moduledoc`, `@shortdoc`)
- Fix false positives for `TrailingWhiteSpace`
- Fix compiler warnings for `Sigils`

### BREAKING CHANGES

These changes concern people writing their own checks for Credo.

- `Credo.SourceFile` struct was refactored: `source`, `lines` and `ast` are now stored in ETS tables.
- `Credo.Config` struct was replaced by `Credo.Execution`.
- `run/3` callbacks for `Credo.Check` are now `run/4` callbacks as they have to receive the execution's `Credo.Execution` struct.

### Config Comments replace `@lint` attributes

`@lint` attributes are deprecated and will be removed in Credo `0.9.0` because
they are causing a compiler warning in Elixir `>= 1.4`.

Users of Credo can now disable individual lines or files for all or just
specific checks.

For now, config comments let you exclude individual files completely

    # credo:disable-for-this-file
    defmodule SomeApp.ThirdPartyCode do
    end

or deactivate specific lines:

    def my_fun do
      # credo:disable-for-next-line
      IO.inspect :this_is_actually_okay
    end

or add the check module to exclude just that one check:

    def my_fun do
      # credo:disable-for-next-line Credo.Check.Warning.IoInspect
      IO.inspect :this_is_actually_okay
    end

or use a Regex to be more flexible which checks to exclude:

    def my_fun do
      # credo:disable-for-next-line /IoInspect/
      IO.inspect :this_is_actually_okay
    end

Here's a list with the syntax options:

* `# credo:disable-for-this-file` - to disable for the entire file
* `# credo:disable-for-next-line` - to disable for the next line
* `# credo:disable-for-previous-line` - to disable for the previous line
* `# credo:disable-for-lines:<count>` - to disable for the given number of lines (negative for previous lines)

### New checks

- Credo.Check.Refactor.LongQuoteBlocks

## 0.7.4

-	Fix false positives in SpacesAroundOperators
- Fix `--all` CLI switch
- Always enforce `strict` mode for `<filename>:<line_no>`
- Improve docs on checks
- Disable `MultiAliasImportRequireUse` by default

### Disabled checks

- Credo.Check.Consistency.MultiAliasImportRequireUse

## 0.7.3

- Fix filename annotation when using `--read-from-stdin`
- Fix filename handling on Windows
- Fix consistency checks triggered by contents of sigils
- Fix consistency checks triggered by contents of charlists

### New check

- Credo.Check.Warning.LazyLogging

## 0.7.2

- Fix `@lint` attribute deprecation hint
- Fix filename handling bug for Windows
- Fix flycheck formatting
- Add param to ignore strings/heredocs in `TrailingWhiteSpace`

### New check

- Credo.Check.Readability.SpaceAfterCommas

## 0.7.1

- Fix `--config_name`CLI switch
- Fix `UI.wrap_at/2` for Unicode strings
- Fix false positive for `ModuleNames`

## 0.7.0

- Added deprecation hint about `@lint` attributes
- Fixed file inclusion/exclusion bug
- Fixed false positives in `SpaceAroundOperators`
- Deprecated `NameRedeclarationBy*` checks
- Fixed false positives in `PipeChainStart`
- Changed `AppendSingleItem`'s priority and make it opt-in
- Renamed `NoParenthesesWhenZeroArity` to `ParenthesesOnZeroArityDefs`
- Fixed a bug in `ParenthesesOnZeroArityDefs`

### Added/deprecated checks

- Credo.Check.Warning.MapGetUnsafePass
- Credo.Check.Refactor.AppendSingleItem
- Credo.Check.Readability.Semicolons

Switched some checks to opt-in by default

- Credo.Check.Readability.Specs
- Credo.Check.Refactor.ABCSize
- Credo.Check.Refactor.VariableRebinding
- Credo.Check.Warning.MapGetUnsafePass
- Credo.Check.Warning.NameRedeclarationByAssignment
- Credo.Check.Warning.NameRedeclarationByCase
- Credo.Check.Warning.NameRedeclarationByDef
- Credo.Check.Warning.NameRedeclarationByFn


## 0.6.1

- Fixed false positives for `StringSigils` in heredocs
- Fixed a bug in `SourceFile.column`

## 0.6.0

- Do not warn about ParenthesesInCondition in one-line `if` call
- Add `--no-strict` CLI switch
- Fixed exit status for `mix credo list`
- Fixed exclusion of checks set to `low` priority

### New Checks

- consistency/multi_alias_import_require_use
- readability/no_parentheses_when_zero_arity
- readability/redundant_blank_lines
- readability/single_pipe
- readability/specs
- readability/string_sigils
- refactor/double_boolean_negation
- refactor/variable_rebinding

## 0.5.3

- Fix crash in CheckForUpdates

## 0.5.2

- Add ability to specify `strict` in `.credo.exs` config file
- Add `no_case?` to variable name checks
- Add `Module.name` utility method
- Fix bug in NameRedeclarationByDef
- Fix bug in LargeNumbers

## 0.5.1

- Use Hex.pm API to retrieve update information for Credo

## 0.5.0

- See below

## 0.4.14

- Fix compiler error due to usage of undocumented Hex APIs (sorry)

## 0.4.13

- Prevent crashing when parsing non-UTF-8 source files
- Fix yet another issue with finding sources
- Fix false positives for PipeChainStart
- Fix false positives for AbcSize
- Remove dead code
- Update deps

## 0.4.12

- Prevent ModuleDoc from checking nested modules for ignored modules
- Fix issue with ParenthesesInCondition
- Fix issue with PipChainStart
- Fix issue with reading from stdin
- Log errors to stderr

## 0.4.11

- Fix compatibility issues with Elixir < 1.2
- Fix yet another issue with finding sources

## 0.4.10

- Fix another issue with finding sources

## 0.4.9

- Fix issues with finding sources
- Don't enforce @moduledoc requirement for Mixfile or Test modules

## 0.4.8

- Add `exclude_functions` option to `PipeChainStart`
- No longer report issues in case of ambiguous aliases in `AliasUsage`
- Fix false positives for `LargeNumbers` in Elixir `>= 1.3.2` (again)
- Lots of refactorings

## 0.4.7

- Ignore module attributes like `@spec` in `AliasUsage`
- Improve source file loading

## 0.4.6

- Add `ignore_specs` option to `MaxLineLength`
- Fix false positives for `LargeNumbers` in Elixir `>= 1.3.2`
- Fix compiler warnings in preparation for Elixir v1.4

## 0.4.5

- Warnings about redeclaring names of Kernel or local functions now only consider function of arity zero.
- Warnings for operations with constant result now ignore division by 1
- Better explanation how to configure checks in `explain` output

## 0.4.4

- New check: readability/parentheses_in_condition

## 0.4.3

- Fix compatibility issues in `Credo.CLI.Command.GenCheck` for Elixir < 1.2

## 0.4.2

- Fix outdated comments regarding .credo.exs in README
- Fix name generator including "Lib." prefix for custom checks

## 0.4.1

- Maintenance release because I apparently don't understand how merging works :sweat:

## 0.4.0

### Custom check support

- Adds support for custom checks in your projects.

  Using two new mix commands `mix credo.gen.config` and `mix credo.gen.check`
  you can generate the boilerplate to include custom checks in your projects.

### BREAKING CHANGE: Checks listed in `.credo.exs`

- Prior to `v0.4.0`, `.credo.exs` contained the full list of checks specific to your project
- Starting with `v0.4.0` the check list in `credo.exs` will be merged with the standard check list, with your definitions overwriting the defaults
- PRO: you can customize individual tasks to your liking and still benefit from additional standard checks with each new release
- CON: this means checks have to be disabled explicitly in `.credo.exs`

### New Checks

- readability/large_numbers
- warning/bool_operation_on_same_values
- warning/unused_file_operation
- warning/unused_path_operation
- warning/unused_regex_operation

### Minor Improvements

- Ready for Elixir 1.3
- Checks for new Credo versions automatically, like Hex does (can be disabled)
- Umbrella apps work out of the box now
- DuplicatedCode can now ignore macro calls
- ModuleDoc now ignores modules declaring exceptions
- ModuleDoc now allows modules to be ignored based on their name
- MatchInCondition now allows "simple" wildcard assignments in conditionals
- Checks analysing all files in the codebase sequentially (consistency checks)
  are now run in parallel
- If `--only` is given, all issues are shown (`mix credo --only MaxLineLength`
  previously yielded no results, since all issues needed `--strict` to actually
  be displayed)

## 0.3.13

- Fix false positives for `NameRedeclarationByDef`.
- Fix false positives for `UnusedEnumOperation`.

## 0.3.12

- Fix false positives for `SpaceInParentheses`.
- Fix false positive for `SpaceAroundOperators`.

## 0.3.11

- Fix a bug with checks on function names when declaring a variable with the name `def`, `defp` or `defmacro`.

## 0.3.10

- Fix a bug resulting in `UnicodeConversionError` for code containing UTF-8 comments.

## 0.3.9

- Fix a bug in `AliasUsage`.

## 0.3.8

- Fix false positives for `AliasUsage`.

## 0.3.7

- Fix false positive for `SpaceAroundOperators`.

## 0.3.6

- Fix false positives for `SpaceAroundOperators` and `PipeChainStart`.
- Add option to read from STDIN for better editor integration

## 0.3.5

- Remove superfluous call to `IO.inspect`.
- Update deps requirements to make HexFaktor happy.

## 0.3.4

- Fix false positives for `SpaceAroundOperators` in binary pattern matches.
- Fix a bug when supplying a single file via the CLI.

## 0.3.3

- Fix false positives for `SpaceAroundOperators` and `SpaceInParentheses`.

## 0.3.2

- `mix do credo, <something-else>` was broken and never ran `<something-else>`, even if `credo` succeeded (exited with exit status 0). Now it runs `<something-else>` as long as `credo` succeeds.

## 0.3.1

- Fix compiler warnings
- Improve copywriting for consistency checks (thx @vdaniuk)

## 0.3.0

### Per-function lint support

- Adds support for `@lint` attributes used to configure linting for specific
  functions.

  For now, this lets you exclude functions completely

      @lint false
      def my_fun do
      end

  or deactivate specific checks *with the same syntax used in the config file*:

      @lint {Credo.Check.Design.TagTODO, false}
      def my_fun do
      end

  or use a Regex instead of the check module to exclude multiple checks at once:

      @lint {~r/Refactor/, false}
      def my_fun do
      end

  Finally, you can supply multiple tuples as a list and combine the above:

      @lint [{Credo.Check.Design.TagTODO, false}, {~r/Refactor/, false}]
      def my_fun do
      end

### New Checks

- consistency/space_around_operators
- consistency/space_in_parentheses

### Minor Improvements

- Add `--format` CLI switch
- Include experimental Flycheck support via `--format=flycheck`
- **Deprecate** `--one-line` CLI switch, use `--format=oneline` instead
- Add convenience alias `--ignore` for `--ignore-checks`
- Fix colors for terminals with light backgrounds (thx @lucasmazza)

## 0.2.6

- Fix false positives for UnusedEnumOperation checks (thx @kbaird)

## 0.2.5

- Fix error occurring when a project has exactly one `defexception` module
- Change the tag for Refactoring Opportunities from "[R]" to "[F]" (thx @rranelli)

## 0.2.4

- Remove unused alias to avoid warning during compilation

## 0.2.3

- Improves docs and UI wording (thx @crack and @jessejanderson)

## 0.2.2

- Adds a missing word to the output of the `categories` command (thx @bakkdoor)

## 0.2.1

- Fixes a problem with CaseTrivialMatches crashing

## 0.2.0

### Error Status

Credo now fails with an exit status != 0 if it shows any issues. This will enable usage of Credo inside CI systems/build chains.

The exit status of each check is customizable and exit statuses of all
encountered checks are collected, uniqued and summed:

    issues
    |> Enum.map(&(&1.exit_status))
    |> Enum.uniq
    |> Enum.reduce(0, &(&1+&2))

This way you can reason
about the encountered issues right from the exit status.

Default values for the checks are based on their category:

    consistency:  1
    design:       2
    readability:  4
    refactor:     8
    warning:     16

So an exit status of 12 tells you that you have only Readability Issues and Refactoring Opportunities, but e.g. no Warnings.

### New Checks

- readability/module_doc
- refactor/case_trivial_matches
- refactor/cond_statements
- refactor/function_arity
- refactor/match_in_condition
- refactor/pipe_chain_start
- warning/operation_with_constant_result
- warning/unused_enum_operation
- warning/unused_keyword_operation
- warning/unused_list_operation
- warning/unused_tuple_operation

### Minor Improvements

- There are two new aliases for command line switches:
  - you can use `--only` as alias for `--checks`
  - you can use `--strict` as alias for `--all-priorities`
- `mix credo --only <checkname>` will always display a full list of results
  (you no longer need to specify `--all` separately)
- `mix credo explain <file:line_number>` now also explains the available configuration parameters for the issue/check
- The ExceptionNames check no longer fails if only a single exception module is found (#22).

## 0.1.10

- Apply many fixes in anticipation of Elixir v1.2 (thx @c-rack)
- Improve docs
- Wrap long issue descriptions in `suggest` command

## 0.1.9

- Add missing `-A` alias for `--all-priorities`
- Improve wording in the CLI a bit

## 0.1.8

- Add `apps/` to default directories

## 0.1.7

- Bugfix to `NameRedeclarationBy\*` checks
- `Sources.exclude` had a bug when excluding directories

## 0.1.6

- Rename CLI switch `--pedantic` to `--all-priorities` (alias is `-A`)
- Fix a bug in SourceFile.column (#7)
- Improve README section about basic usage, commands and issues

## 0.1.1 - 0.1.5

Multiple Hex releases due to the fact that I apparently don't understand how deps compilation works :sweat:

## 0.1.0

Initial release
