# Basic Usage

To run credo in the current project, **just type**:

```bash
$ mix credo
```

This will run the code analysis and suggest places to edit your code.

If you want to enforce a style guide and need a more traditional linting experience, try

```bash
$ mix credo --strict
```

You will get output like this:

```bash
┃  Refactoring opportunities
┃ 
┃ [F] ↗ Avoid negated conditions in if-else blocks.
┃       lib/credo/check.ex:306 #(Credo.Check.deprecated_def_explanations)
┃ [F] ↗ Avoid negated conditions in if-else blocks.
┃       lib/credo/check.ex:285 #(Credo.Check.deprecated_def_default_params)
```

Since Credo is all about teaching people, you can find out more about that particular entry.
Just copy the `<filename>:<line-number>[:column]` combo into the command:

```bash
$ mix credo lib/credo/check.ex:306
```

The result is an explanation of the issue:

```bash
┃ 
┃   [F] Category: refactor 
┃    ↗  Priority: high 
┃ 
┃       Avoid negated conditions in if-else blocks.
┃       lib/credo/check.ex:306 (Credo.Check.deprecated_def_explanations)
┃ 
┃    __ CODE IN QUESTION
┃ 
┃   304     explanation = Module.get_attribute(env.module, :explanation)
┃   305 
┃   306     if not is_nil(explanation) do
┃   307       # deprecated - remove once we ditch @explanation
┃   308       quote do
┃       
┃    __ WHY IT MATTERS
┃ 
┃       An `if` block with a negated condition should not contain an else block.
┃       
┃       So while this is fine:
┃       
┃           if not allowed? do
┃             raise "Not allowed!"
┃           end
┃       
┃       The code in this example ...
┃       
┃           if not allowed? do
┃             raise "Not allowed!"
┃           else
┃             proceed_as_planned()
┃           end
┃       
┃       ... should be refactored to look like this:
┃       
┃           if allowed? do
┃             proceed_as_planned()
┃           else
┃             raise "Not allowed!"
┃           end
┃       
┃       The same goes for negation through `!` instead of `not`.
┃       
┃       The reason for this is not a technical but a human one. It is easier to wrap
┃       your head around a positive condition and then thinking "and else we do ...".
┃       
┃       In the above example raising the error in case something is not allowed
┃       might seem so important to put it first. But when you revisit this code a
┃       while later or have to introduce a colleague to it, you might be surprised
┃       how much clearer things get when the "happy path" comes first.
```

Credo can also provide the output of every command as JSON:

```bash
$ mix credo lib/credo/check.ex:306 --format json
{
  "explanations": [
    {
      "category": "refactor",
      "check": "Elixir.Credo.Check.Refactor.NegatedConditionsWithElse",
      "column": null,
      "explanation_for_issue": "An `if` block with a negated condition should not contain an else block.\n\nSo while this is fine:\n\n    if not allowed? do\n      raise \"Not allowed!\"\n    end\n\nThe code in this example ...\n\n    if not allowed? do\n      raise \"Not allowed!\"\n    else\n      proceed_as_planned()\n    end\n\n... should be refactored to look like this:\n\n    if allowed? do\n      proceed_as_planned()\n    else\n      raise \"Not allowed!\"\n    end\n\nThe same goes for negation through `!` instead of `not`.\n\nThe reason for this is not a technical but a human one. It is easier to wrap\nyour head around a positive condition and then thinking \"and else we do ...\".\n\nIn the above example raising the error in case something is not allowed\nmight seem so important to put it first. But when you revisit this code a\nwhile later or have to introduce a colleague to it, you might be surprised\nhow much clearer things get when the \"happy path\" comes first.\n",
      "filename": "lib/credo/check.ex",
      "line_no": 306,
      "message": "Avoid negated conditions in if-else blocks.",
      "priority": 12,
      "related_code": [
        [304, "    explanation = Module.get_attribute(env.module, explanation)"],
        [305, ""],
        [306, "    if not is_nil(explanation) do"],
        [307, "      # deprecated - remove once we ditch @explanation"],
        [308, "      quote do"]
      ],
      "scope": "Credo.Check.deprecated_def_explanations",
      "trigger": "!"
    }
  ]
}
```

### Using Credo as stand alone

If you do not want or are not allowed to include Credo in the current project, you can also install it as an archive. 
For this, you also need to install [bunt](https://github.com/rrrene/bunt):

```bash
git clone git@github.com:rrrene/bunt.git
cd bunt
mix archive.build
mix archive.install
cd -
git clone git@github.com:rrrene/credo.git
cd credo
mix deps.get
mix archive.build
mix archive.install
```

**Important:** You have to install `bunt` as well:

```bash
git clone https://github.com/rrrene/bunt
cd bunt
mix archive.build
mix archive.install
```

You will now be able to invoke credo as usual through Mix with `mix credo`. This option is especially handy so credo can be used by external editors.

## Issues

Like any code linter, Credo reports issues. Contrary to many other linters these issues are not created equal. Each issue is assigned a priority, based on a base priority set by the config and a dynamic component based on violation severity and location in the source code.

These priorities hint at the importance of each issue and are displayed in the command-line interface using arrows: ↑ ↗ → ↘ ↓

By default, only issues with a positive priority are part of the report (↑ ↗ →).

## Commands

### suggest (default command)

`suggest` is the default command of Credo. It suggests issues to fix in your code, but it cuts the list to a digestable count. If you want to see the full list, use the `--all`  switch.

Example usage:

```bash
$ mix credo                         # display standard report
$ mix credo suggest                 # same thing, since it's the default command
$ mix credo --strict --format=json  # include low priority issues, output as JSON

$ mix credo suggest --help          # more options
```

[Learn more ...](suggest_command.html).


### list

`list` also suggests issues, but it groups them by file and does NOT cut the list to a certain count.

Example usage:

```bash
$ mix credo list                      # show issues grouped by file
$ mix credo list --format oneline     # show issues grouped by file, one issue per line
$ mix credo list --format oneline -a  # same thing, include low priority issues

$ mix credo list --help               # more options
```

[Learn more ...](list_command.html).


### explain

`explain` allows you to dig deeper into an issue, by showing you details about the issue and the reasoning by it being reported. To be convenient, you can just copy-paste the `filename:line_number:column` string from the report behind the Credo command to check it out.

Example usage:

```bash
$ mix credo lib/my_app/server.ex:10:24          # show explanation for the issue
$ mix credo explain lib/my_app/server.ex:10:24  # same thing
```

*Credit where credit is due:* This is inspired by how you can snap the info from failed tests behind `mix test`.

[Learn more ...](explain_command.html).


### categories

`categories` shows you all issue categories and explains their semantics.

There are no additional options.


### info

`info` shows you information relevant to investigating errors and submitting bug reports.

Example usage:

```bash
$ mix credo info
$ mix credo info --verbose
$ mix credo info --verbose --format=json
```

### Further reading

If you are interested in more ways to configure Credo, continue reading in the following sections:

* [CLI switches](cli_switches.html)
* [Configuration file](config_file.html)
