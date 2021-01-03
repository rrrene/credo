# Exit Status

Credo succeeds with an exit status of 0 (like any other program).

Credo fails with an exit status between 1 and 127 if it shows any issues.

Exit statuses above or equal to 128 indicate an actual runtime error during analysis itself.

This enables shell based pipeline workflows (e.g. on CI systems) which test Credo compliance.

## Issue Statuses

The exit status of each check is used to construct a bit map of the types of issues which were encountered by or-ing them together to produce the final result:

```elixir
use Bitwise

issues
|> Enum.map(&(&1.exit_status))
|> Enum.reduce(0, &(&1 ||| &2))
```

This way you can reason about the encountered issues right from the exit status.

Default values for the checks are based on their category:

    consistency:          1
    design:               2
    readability:          4
    refactor:             8
    warning:              16

Let's see what this means using an example:

```bash
$ mix credo

[...snip...]

$ echo $?
12
```

So an exit status of `12` tells you that you have only Readability Issues (`4`) and Refactoring Opportunities (`8`), but e.g. no Warnings.

Naturally, custom checks and plugins can provide their own exit statuses.

```bash
<custom category>:    32
<custom category>:    64
```

## Actual & Custom Errors

To also allow for actual errors, an exit status of `>= 128` signals something went wrong during analysis itself.

Since one cannot combine these, they do not follow the bitwise notation described above:

```bash
Generic Credo error:  128
Credo Config errors:  129-131
Reserved errors:      132-191
```

Naturally, plugins can provide their own exit statuses.

```bash
<custom errors>:      192-255
```
