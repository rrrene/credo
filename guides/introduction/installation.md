# Installation

The easiest way to add Credo to your project is by [using Mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html).

Add `:credo` as a dependency to your project's `mix.exs`:

```elixir
defp deps do
  [
    {:credo, "~> 1.1", only: [:dev, :test], runtime: false}
  ]
end
```

And run:

```shell
$ mix deps.get
```

