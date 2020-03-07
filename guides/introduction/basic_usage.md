# Basic Usage

To run credo in the current project, **just type**:

```shell
$ mix credo
```

This will run the code analysis and suggest places to edit your code.

If you want to enforce a style guide and need a more traditional linting experience, try

```shell
$ mix credo --strict
```

You will get output like this:

```shell
┃  Refactoring opportunities
┃ 
┃ [F] ↗ Avoid negated conditions in if-else blocks.
┃       lib/credo/check.ex:306 #(Credo.Check.deprecated_def_explanations)
┃ [F] ↗ Avoid negated conditions in if-else blocks.
┃       lib/credo/check.ex:285 #(Credo.Check.deprecated_def_default_params)
```

Since Credo is all about teaching people, you can find out more about that particular entry.
Just copy the `<filename>:<line-number>[:column]` combo into the command:

```shell
$ mix credo lib/credo/check.ex:306
```

The result is an explanation of the issue:

```shell
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

```shell
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

If you are interested in more ways to configure Credo, continue reading in the following sections:

* [CLI switches](cli_switches.html)
* [Configuration file](config_file.html)
