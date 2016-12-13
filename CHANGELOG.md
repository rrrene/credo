# Changelog

## 0.6.0 (pre)

- Do not warn about ParenthesesInCondition in one-line `if` call
- Add `--no-strict` CLI switch
- Fixed exit status for `mix credo list`

### New Checks

- consistency/multi_alias_import_require_use
- readability/no_parentheses_when_zero_arity
- readability/redundant_blank_lines
- readability/single_pipe
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

- Fix error occuring when a project has exactly one `defexception` module
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
