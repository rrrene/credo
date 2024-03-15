# Inline Config Comments

Users of Credo can now disable individual lines or files for all or just
specific checks.

```elixir
defp my_fun() do
  # credo:disable-for-next-line
  IO.inspect {:we_want_this_inspect_in_production!}
end
```

There are four config comments:

* `# credo:disable-for-this-file` - to disable for the entire file
* `# credo:disable-for-next-line` - to disable for the next line
* `# credo:disable-for-previous-line` - to disable for the previous line
* `# credo:disable-for-lines:<count>` - to disable for the given number of lines (negative for previous lines)


## `credo:disable-for-this-file`

This config comment can be used to disable Credo for the current file:

```elixir
# credo:disable-for-this-file
defmodule MyModule do
  # ...
end
```

You can also provide the name of the check you want to disable:

```elixir
# credo:disable-for-this-file Credo.Check.Warning.IoInspect
defmodule MyModule do
  # ...
end
```

Lastly, you can put a regular expression (`/.+/`) instead of a check name to disable multiple checks (or if you do not want to type out the checks):

```elixir
# credo:disable-for-this-file /\.Warning\./
defmodule MyModule do
  # ...
end
```

## `credo:disable-for-next-line`

This config comment can be used to disable Credo for the following line of source code:

```elixir
defp my_fun() do
  # credo:disable-for-next-line
  IO.inspect {:we_want_this_inspect_in_production!}
end
```

You can also provide the name of the check you want to disable:

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

## `credo:disable-for-previous-line`

This config comment can be used to disable Credo for the preceding line of source code:

```elixir
defp my_fun() do
  IO.inspect {:we_want_this_inspect_in_production!}
  # credo:disable-for-previous-line
end
```

You can also provide the name of the check you want to disable:

```elixir
defp my_fun() do
  IO.inspect {:we_want_this_inspect_in_production!}
  # credo:disable-for-previous-line Credo.Check.Warning.IoInspect
end
```

Lastly, you can put a regular expression (`/.+/`) instead of a check name to disable multiple checks (or if you do not want to type out the checks):

```elixir
defp my_fun() do
  IO.inspect {:we_want_this_inspect_in_production!}
  # credo:disable-for-previous-line /\.Warning\./
end
```

## `credo:disable-for-lines:<count>`

This config comment can be used to disable Credo for the following `<count>` lines of source code:

```elixir
# credo:disable-for-lines:3
defp my_fun() do
  IO.inspect {:we_want_this_inspect_in_production!}
end
```

You can also provide the name of the check you want to disable:

```elixir
# credo:disable-for-lines:3 Credo.Check.Warning.IoInspect
defp my_fun() do
  IO.inspect {:we_want_this_inspect_in_production!}
end
```

Lastly, you can put a regular expression (`/.+/`) instead of a check name to disable multiple checks (or if you do not want to type out the checks):

```elixir
# credo:disable-for-lines:3 /\.Warning\./
defp my_fun() do
  IO.inspect {:we_want_this_inspect_in_production!}
end
```
