# Mix Tasks

After incuding Credo in a project's dependencies (see [Installation](installation.html)), there are a number of built-in mix tasks available:

```bash
$ mix help | grep -i credo
mix credo                 # Run code analysis (use `--help` for options)
mix credo.gen.check       # Generate a new custom check for Credo
mix credo.gen.config      # Generate a new config for Credo
```

If you want to know more about `mix`, check out [Introduction to Mix](https://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html).

`mix credo`

Runs Credo's analysis.
Check out [Configuration](configuration.html) on how to customize inputs and outputs.

`mix credo.gen.check`

Generates a custom Credo check.

`mix credo.gen.config`

Generates a Credo config file.
Check out [Configuration](configuration.html) on how to customize it.
