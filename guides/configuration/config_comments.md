# Inline Config Comments

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
