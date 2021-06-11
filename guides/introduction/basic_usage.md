# Basic Usage

Since Credo is all about teaching people, you can find out more about that particular entry.

## Run Analysis

To run credo in the current project, just type:

```bash
$ mix credo
```

This will run the code analysis and suggest places to edit your code.

## Explain Issues

Running Credo will yield issues like this:

```bash
┃  Refactoring opportunities
┃
┃ [F] ↗ Avoid negated conditions in if-else blocks.
┃       lib/foo/bar.ex:306 #(Foo.Bar.deprecated_def_explanations)
```

To find out more about the issue, just append its location to the `credo` command:

```bash
mix credo lib/foo/bar.ex:306
```

The result is an explanation of the issue, including the check that raised the issue, its configuration options and how to disable it.

## Advanced Usage

### Strict Analysis

Like any code linter, Credo reports issues. Contrary to many other linters these issues are not created equal. Each issue is assigned a priority, based on a base priority set by the config and a dynamic component based on violation severity and location in the source code.

These priorities hint at the importance of each issue and are displayed in the command-line interface using arrows: ↑ ↗ → ↘ ↓

By default, only issues with a positive priority are part of the report (↑ ↗ →).

To include all issues, just type:

```bash
mix credo --strict
```

### Format output as JSON

Credo can provide the output of every command as JSON:

```bash
$ mix credo lib/foo/bar.ex:306 --format json
```

```json
{
  "explanations": [
    {
      "category": "refactor",
      "check": "Elixir.Foo.Bar.Refactor.NegatedConditionsWithElse",
      "column": null,
      "explanation_for_issue": "An `if` block with a negated condition should not contain an else block.\n\nSo while this is fine:\n\n    if not allowed? do\n      raise \"Not allowed!\"\n    end\n\nThe code in this example ...\n\n    if not allowed? do\n      raise \"Not allowed!\"\n    else\n      proceed_as_planned()\n    end\n\n... should be refactored to look like this:\n\n    if allowed? do\n      proceed_as_planned()\n    else\n      raise \"Not allowed!\"\n    end\n\nThe same goes for negation through `!` instead of `not`.\n\nThe reason for this is not a technical but a human one. It is easier to wrap\nyour head around a positive condition and then thinking \"and else we do ...\".\n\nIn the above example raising the error in case something is not allowed\nmight seem so important to put it first. But when you revisit this code a\nwhile later or have to introduce a colleague to it, you might be surprised\nhow much clearer things get when the \"happy path\" comes first.\n",
      "filename": "lib/foo/bar.ex",
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
      "scope": "Foo.Bar.deprecated_def_explanations",
      "trigger": "!"
    }
  ]
}
```


## Further reading

If you are interested in more ways to configure Credo, continue reading in the following sections:

* [CLI switches](../configuration/cli_switches.md)
* [Configuration file](../configuration/config_file.md)
