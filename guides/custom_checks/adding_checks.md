# Adding Custom Checks

There comes a time when Credo does not feature the check you need or where you want to test a project- or domain-specific aspect of your codebase.

This is when you should consider implementing a Custom Check.

Custom checks are simply modules implementing the `Credo.Check` behaviour, which most of the time means that it is a module with a `run/2` function returning a list of `Credo.Issue` structs:

    # lib/checks/my_check.ex
    defmodule MyProject.Checks.MyCheck do
      use Credo.Check

      def run(%SourceFile{} = source_file, params) do
        #
      end
    end

Check `Credo.Check` for more technical information.

### Our first check: Policing module attributes

Sometimes the conventions for names of module attributes change within a development team and you want to encourage people to stop using the old naming scheme for module attributes to avoid endless bikeshedding about whether or not the new naming policy was needed in the first place.

So, let's implement a check for this completely made up scenario!

### Minimal check & config

First, we add the necessary Elixir module for the check and, for now, just return an empty list of issues.

```elixir
# lib/my_project/checks/reject_module_attributes.ex
defmodule MyProject.Checks.RejectModuleAttributes do
  # Set up the behaviour and make this module a "check":
  use Credo.Check

  # The minimum each check has to implement is a `run/2` function which returns the found issues:
  def run(source_file, params \\ []) do
    []
  end
end
```

To run our new check, we also need to add the necessary `:requires` and `:checks` in our Credo config file:

```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      requires: ["./lib/my_project/checks/**/*.ex"],
      checks: [
        {MyProject.Checks.RejectModuleAttributes, []}
      ]
    }
  ]
}
```

This tells Credo to require all files in our checks directory and to enable the `RejectModuleAttributes` check.

### Getting it working

For a first implementation, our check should look into all modules and report "violations" against a list of rejected names.

```elixir
# lib/my_project/checks/reject_module_attributes.ex
defmodule MyProject.Checks.RejectModuleAttributes do
  use Credo.Check

  # Let's say we want to report module attributes named `@checkdoc`
  @rejected_names [:checkdoc]

  def run(source_file, params \\ []) do
    # IssueMeta helps keeping track of the source file and the check's params
    # (technically, it's just a custom tagged tuple)
    issue_meta = IssueMeta.for(source_file, params)

    # we'll walk the `source_file`'s AST and look for module attributes matching `@rejected_names`
    Credo.Code.prewalk(source_file, &traverse(&1, &2, @rejected_names, issue_meta))
  end

  # This matches on the AST structure of module attributes.
  defp traverse({:@, _, [{name, meta, [_string]} | _]} = ast, issues, rejected_names, issue_meta) do
    if Enum.member?(rejected_names, name) do
      {ast, issues ++ issue_for(name, meta[:line], issue_meta)}
    else
      {ast, issues}
    end
  end

  # For all AST nodes not matching the pattern above, we simply do nothing:
  defp traverse(ast, issues, _rejected_names, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(trigger, line_no, issue_meta) do
    format_issue(
      issue_meta,
      message: "There should be no `@#{trigger}` module attributes.",
      trigger: "@#{trigger}",
      line_no: line_no
    )
  end
end
```

Traversal of the AST is done via `Credo.Code.prewalk/2`, which is a light wrapper around `Macro.prewalk/3`, taking a `Credo.SourceFile` struct instead of an AST.

You can use `Code.string_to_quoted!/1` to look at the AST structure for code snippets:

```elixir
iex> Code.string_to_quoted!("@my_attribute 23")
{:@, [line: 1], [{:my_attribute, [line: 1], [23]}]}
```

### Adding configuration parameters

Next, we should have a config parameter which allows us to define which module attribute names are no longer allowed.

```elixir
defmodule MyProject.Checks.RejectModuleAttributes do
  # To add a parameter, we use the `:param_defaults` keyword with `use Credo.Check`:
  use Credo.Check, param_defaults: [reject: [:checkdoc]]

  def run(source_file, params \\ []) do
    # To get a parameter, we use `Params.get/3`, which returns the given parameter from the config
    # or the default we registered above:
    reject = Params.get(params, :reject, __MODULE__)
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, reject, issue_meta))
  end

  # ...
end
```

We can now use `.credo.exs` to configure the `:reject` param.

If the param is not declared ...

    {MyProject.Checks.RejectModuleAttributes, []}

... then the default from your check is used.

If the param is declared, it overwrites the default, meaning that this ...

    {MyProject.Checks.RejectModuleAttributes, [reject: [:shortdoc]]}

... forbids `@shortdoc`, but allows `@checkdoc` again.

Our final `.credo.exs` might look something like this:

```elixir
# .credo.exs
%{
  configs: [
    %{
      name: "default",
      requires: ["./lib/my_project/checks/**/*.ex"],
      checks: [
        {MyProject.Checks.RejectModuleAttributes, [reject: [:checkdoc, :other_attr]]}
      ]
    }
  ]
}
```

### Finalizing the check

To really make this a full-fledged Credo check, we have to configure its priority, category and describe what it does (you can find a description of the options in `Credo.Check`).

```elixir
defmodule MyProject.Checks.RejectModuleAttributes do
  use Credo.Check,
    base_priority: :high,
    category: :readability,
    param_defaults: [reject: []],
    explanations: [
      check: """
      Look, sometimes the policies for names of module attributes change.
      We want to make sure that all module attributes adhere to the newest standards of ACME Corp.

      We do not want to discuss this policy, we just want to stop you from using the old
      module attributes :)
      """,
      params: [reject: "This check warns about module attributes with any of the given names."]
    ]

  # ...
end
```

You can now use Credo's `explain` command ...

```bash
$ mix credo explain MyProject.Checks.RejectModuleAttributes
```

... to show a description of your new check:

```bash
  MyProject.Checks.MyIExPry
┃ 
┃   [R] Category: readability 
┃    ↗  Priority: high 
┃ 
┃    __ WHY IT MATTERS
┃ 
┃       Look, sometimes the policies for names of module attributes change.
┃       We want to make sure that all module attributes adhere to the newest standards of ACME Corp.
┃       
┃       We do not want to discuss this policy, we just want to stop you from using the old
┃       module attributes :)
┃ 
┃    __ CONFIGURATION OPTIONS
┃ 
┃       To configure this check, use this tuple
┃ 
┃         {MyProject.Checks.RejectModuleAttributes, <params>}
┃ 
┃       with <params> being false or any combination of these keywords:
┃ 
┃         reject:                Names of module attributes that are no longer allowed
┃                                (defaults to [])
┃ 

```

And that's it. Here's the final check:

```elixir
defmodule MyProject.Checks.RejectModuleAttributes do
  use Credo.Check,
    base_priority: :high,
    category: :readability,
    param_defaults: [reject: []],
    explanations: [
      check: """
      Look, sometimes the policies for names of module attributes change.
      We want to make sure that all module attributes adhere to the newest standards of ACME Corp.

      We do not want to discuss this policy, we just want to stop you from using the old
      module attributes :)
      """,
      params: [reject: "Names of module attributes that are no longer allowed"]
    ]

  def run(source_file, params \\ []) do
    reject = Params.get(params, :reject, __MODULE__)

    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(source_file, &traverse(&1, &2, reject, issue_meta))
  end

  defp traverse({:@, _, [{name, meta, [_string]} | _]} = ast, issues, rejected_names, issue_meta) do
    if Enum.member?(rejected_names, name) do
      {ast, issues ++ issue_for(name, meta[:line], issue_meta)}
    else
      {ast, issues}
    end
  end

  defp traverse(ast, issues, _rejected_names, _issue_meta) do
    {ast, issues}
  end

  defp issue_for(trigger, line_no, issue_meta) do
    format_issue(
      issue_meta,
      message: "There should be no `@#{trigger}` module attributes.",
      trigger: trigger,
      line_no: line_no
    )
  end
end
```

Next, let's see how we can [write tests for our custom check!](testing_checks.html)