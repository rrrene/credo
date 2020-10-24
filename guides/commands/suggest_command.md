
# mix credo suggest

`suggest` suggests issues to fix in your code, but it cuts the list to a digestable count.
It is the default command of Credo.

If you want to see the full list, use the `--all`  switch.

Example usage:

```shell
$ mix credo                         # display standard report
$ mix credo suggest                 # same thing, since it's the default command
$ mix credo --strict --format=json  # include low priority issues, output as JSON
$ mix credo suggest --help          # more options

$ mix credo suggest --format json
$ mix credo suggest lib/**/*.ex --only consistency --strict
$ mix credo suggest --checks-without-tag formatter --checks-without-tag controversial
```
