# Installation

The easiest way to add Credo to your project is by [using Mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html).

Add `:credo` as a dependency to your project's `mix.exs`:

```elixir
defp deps do
  [
    {:credo, "~> 1.7", only: [:dev, :test], runtime: false}
  ]
end
```

And run:

```bash
$ mix deps.get
```

## Compatibility

Credo aims to stay compatible with the list of [Elixir minor releases mentioned in the Elixir docs](https://hexdocs.pm/elixir/compatibility-and-deprecations.html).

These are the releases that are actively tested on CI.

Please note that Credo sometimes stays technically compatible with even earlier versions coincidentally.
