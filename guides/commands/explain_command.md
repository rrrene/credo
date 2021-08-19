# mix credo explain

`explain` allows you to dig deeper into an issue, by showing you details about the issue and the reasoning by it being reported.
As a convenience, you can just copy-paste the `filename:line_number:column` string from the report behind the Credo command to check it out.

Example usage:

```bash
$ mix credo

[...]

┃ [C] ↗ There is no whitespace around parentheses/brackets most of the time, but here there is.
┃       lib/my_app/server.ex:10:24 #(Credo.Code.InterpolationHelperTest)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^
          copy this and use it with `mix credo`!

[...]

$ mix credo lib/my_app/server.ex:10:24          # show explanation for the issue
```

Please note that you do *not* have to specifiy the `explain` command explicitly when using an issue location:

```bash
$ mix credo lib/my_app/server.ex:10:24          # short-hand without `explain`
$ mix credo explain lib/my_app/server.ex:10:24  # identical to this
```

*Credits:* This is inspired by how you can snap the info from failed tests behind `mix test`.

## Command Line Switches

### `--format`

Display the explanation in a specific format (json)

```bash
$ mix credo explain lib/my_app/server.ex:10:24 --format json
```
