# Credo [![Build Status](https://travis-ci.org/rrrene/credo.svg?branch=master)](https://travis-ci.org/rrrene/credo)

Credo is a static code analysis tool for the Elixir language with a focus on teaching.

## What can it do?

`credo` can show you refactoring opportunities in your code, complex and duplicated code fragments, warn you about common mistakes, show inconsistencies in your naming scheme and - if needed - help you enforce a desired coding style.

If you are a Rubyist it is best described as an opinionated mix between [Inch](https://github.com/rrrene/inch) and [Rubocop](https://github.com/bbatsov/rubocop).



## Installation

Add as a dependency in your mix.exs file:

```elixir
defp deps do
  [
    {:credo, "~> 0.1.0"}
  ]
end
```

And run:

    mix deps.get



## Basic Usage

To run credo in the current project, **just type**:

    $ mix credo

This will run the code analysis and suggest places to edit your code.

If you want a **full list instead of suggestions** just type:

    $ mix credo list

You will get output like this:

    ┃ Refactoring opportunities
    ┃
    ┃ [R] ↗ If/else blocks should not have a negated condition in `if`.
    ┃       lib/phoenix/channel.ex:26 (Phoenix.Channel.subscribe)
    ┃ [R] → Function is too complex (max ABC is 15, was 43).
    ┃       lib/phoenix/router.ex:563:8 (Phoenix.Router.add_resources)
    ┃ [R] → Function is too complex (max ABC is 15, was 16).
    ┃       lib/phoenix/router/socket.ex:12:12 (Phoenix.Router.Socket.channel)
    ┃

Now you might want to know more about that particular entry, **just copy the filename+line-number combo into the command**:

    $ mix credo lib/phoenix/channel.ex:26

    ┃ Phoenix.Channel
    ┃
    ┃   [R] Category: refactor
    ┃    ↗  Priority: medium
    ┃
    ┃       If/else blocks should not have a negated condition in `if`.
    ┃       lib/phoenix/channel.ex:26 (Phoenix.Channel.subscribe)
    ┃
    ┃    __ CODE IN QUESTION
    ┃
    ┃       if !Socket.authenticated?(socket, channel, topic) do
    ┃
    ┃    __ WHY IT MATTERS
    ┃
    ┃       An `if` block with a negated condition should not contain an else block.
    ┃
    ┃       So while this is fine:
    ┃
    ┃           if !allowed? do
    ┃             raise "Not allowed!"
    ┃           end
    ┃
    ┃       The code in this example ...
    ┃
    ┃           if !allowed? do
    ┃             raise "Not allowed!"
    ┃           else
    ┃             proceed_as_planned
    ┃           end
    ┃
    ┃       ... should be refactored to look like this:
    ┃
    ┃           if allowed? do
    ┃             proceed_as_planned
    ┃           else
    ┃             raise "Not allowed!"
    ┃           end
    ┃
    ┃       The reason for this is not a technical but a human one. It is easier to wrap
    ┃       your head around a positive condition and then thinking "and else we do ...".
    ┃
    ┃       In the above example raising the error in case something is not allowed
    ┃       might seem so important to put it first. But when you revisit this code a
    ┃       while later or have to introduce a colleague to it, you might be surprised
    ┃       how much clearer things get when the "happy path" comes first.



## Configuration


### .credo.exs

Credo is configured via a file called `.credo.exs`. This file can live in your project's `config/` or root folder, both is fine.

Take a look at Credo's own `.credo.exs` for an [example configuration](https://github.com/rrrene/credo/blob/master/.credo.exs).


### Only run some checks

To ignore selected checks, you can use the `--checks` or the `-c` alias.

```bash
# to only run the Readability checks, use:

$ mix credo -c readability

# to only run Readability checks and Warnings, use:

$ mix credo -i readability,warning
```

The second example illustrates how the command takes a comma-separated list. All commands matching **any** of the passed items will be run.

You can use partial names to quickly run checks. `mix credo -c todo` will show all `# TODO` comments since `todo` will match Credo.Check.Design.Tag**TODO**. `mix credo -c inspect` will show you all calls to `IO.inspect` since it matches Credo.Check.Warning.Io**Inspect**.


### Ignore some checks

To ignore selected checks, you can use the `--ignore-checks` or the `-i` alias.

```bash
# to ignore all Readability checks, use:

$ mix credo -i readability

# to ignore all Readability checks and the DuplicatedCode check, use:

$ mix credo -i readability,duplicated
```

The second example illustrates how the command takes a comma-separated list. All commands matching any of the passed items will be ignored.

You can use partial names to quickly exclude checks. `mix credo -i nameredec` will exclude all checks for variables/parameters having the same name as declared functions by matching Credo.Check.Warning.**NameRedeclarationBy...**


### Show code snippets in the output

Use the `--verbose` switch to include the code snippets in question in the output.


### Show compact list

Use the `--one-line` switch to format the output to represent each issue by a single line.


### Show all issues including low priority ones

Use the `--all-priorities` switch to include low priority issues in the output.



## Commands

### suggest (default command)

`suggest` is the default command of Credo. It suggests issues to fix in your code, but it cuts the list to a digestable count. If you want to see the full list, use the `--all`  switch.

Example usage:

    $ mix credo                     # display standard report
    $ mix credo suggest             # same thing, since it's the default command
    $ mix credo --all --one-line    # include low priority issues, one issue per line

    $ mix credo suggest --help      # more options


### list

`list` also suggests issues, but it groups them by file and does NOT cut the list to a certain count.

Example usage:

    $ mix credo list                # show issues grouped by file
    $ mix credo list --one-line     # show issues grouped by file, one issue per line
    $ mix credo list --one-line -a  # same thing, include low priority issues

    $ mix credo list --help         # more options


### explain

`explain` allows you to dig deeper into an issue, by showing you details about the issue and the reasoning by it being reported. To be convenient, you can just copy-paste the `filename:line_number:column` string from the report behind the Credo command to check it out.

*Credits:* This is inspired by how you can snap the info from failed tests behind `mix test`.

Example usage:

    $ mix credo lib/my_app/server.ex:10:24          # show explanation for the issue
    $ mix credo explain lib/my_app/server.ex:10:24  # same thing

There are not additional options.



## Issues

Like any code linter, Credo reports issues. Contrary to many other linters these issues are not created equal. Each issue is assigned a priority, based on a base priority set by the config and a dynamic component based on violation severity and location in the source code.

These priorities hint at the importance of each issue and are displayed in the command-line interface using arrows: ↑ ↗ → ↘ ↓

By default, only issues with a positive priority are part of the report (↑ ↗ →).



## Checks


### Consistency

These checks take a look at your code and ensure a consistent coding style. Using tabs or spaces? Both is fine, just don't mix them or Credo will tell you.


### Readability

Readability checks do not concern themselves with the technical correctness of your code, but how easy it is to digest.


### Refactoring Opportunities

The Refactor checks show you opportunities to avoid future problems and technical dept.


### Software Design

While refactor checks show you possible problems, these checks try to highlight possibilities, like - potentially intended - duplicated code or _TODO_ and _FIXME_ comments.


### Warnings

These checks warn you about things that are potentially dangerous, like a missed call to `IEx.pry` or a call to String.downcase without saving the result.



## Contributing

1. [Fork it!](http://github.com/rrrene/credo/fork)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request



## Author

René Föhring (@rrrene)



## License

Credo is released under the MIT License. See the LICENSE file for further
details.
