# mix credo list

`list` suggests issues, grouping them by file and NOT limitting the list to a certain count.

## Examples

Example usage:

    $ mix credo list                      # show issues grouped by file
    $ mix credo list --format oneline     # show issues grouped by file, one issue per line
    $ mix credo list --format oneline -a  # same thing, include low priority issues

    $ mix credo list --help               # more options

## Command Line Switches

The command line switches are identical to [command line switches of the `suggest` command](suggest_command.html#command-line-switches).
