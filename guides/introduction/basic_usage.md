# Basic Usage

To run credo in the current project, **just type**:

```shell
$ mix credo
```

This will run the code analysis and suggest places to edit your code.

**If you want to enforce a style guide** and need a more traditional linting experience, try

```shell
$ mix credo --strict
```

and continue reading in the [Configuration](configuration.md) section.

You will get output like this:

```shell
┃ Refactoring opportunities
┃
┃ [R] ↗ If/else blocks should not have a negated condition in `if`.
┃       lib/phoenix/channel.ex:26 (Phoenix.Channel.subscribe)
┃ [R] → Function is too complex (max ABC is 15, was 43).
┃       lib/phoenix/router.ex:563:8 (Phoenix.Router.add_resources)
┃ [R] → Function is too complex (max ABC is 15, was 16).
┃       lib/phoenix/router/socket.ex:12:12 (Phoenix.Router.Socket.channel)
┃
```

Now you might want to know more about that particular entry, **just copy the filename+line-number combo into the command**:

```shell
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
```


