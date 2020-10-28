# mix credo list

`list` also suggests issues, but it groups them by file and does NOT cut the list to a certain count.

Example usage:

    $ mix credo list                      # show issues grouped by file
    $ mix credo list --format oneline     # show issues grouped by file, one issue per line
    $ mix credo list --format oneline -a  # same thing, include low priority issues

    $ mix credo list --help               # more options
