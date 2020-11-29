# Credo [![CI Tests](https://github.com/rrrene/credo/workflows/CI%20Tests/badge.svg)](https://github.com/rrrene/credo/actions?query=branch%3Amaster) [![Inline docs](https://inch-ci.org/github/rrrene/credo.svg?branch=master)](https://inch-ci.org/github/rrrene/credo)

Credo is a static code analysis tool for the Elixir language with a focus on teaching and code consistency.

It can show you refactoring opportunities in your code, complex code fragments, warn you about common mistakes, show inconsistencies in your naming scheme and - if needed - help you enforce a desired coding style.


![Credo](https://raw.github.com/rrrene/credo/master/assets/screenshot.png)


## Installation and Usage

The easiest way to add Credo to your project is by [using Mix](http://elixir-lang.org/getting-started/mix-otp/introduction-to-mix.html).

Add `:credo` as a dependency to your project's `mix.exs`:

```elixir
defp deps do
  [
    {:credo, "~> 1.5", only: [:dev, :test], runtime: false}
  ]
end
```

And run:

    $ mix deps.get

    $ mix credo

## Documentation

Documentation is [available on Hexdocs](https://hexdocs.pm/credo/)

## Integrations

### IDE/Editor

Some IDEs and editors are able to run Credo in the background and mark issues inline.

* [IntelliJ Elixir](https://github.com/KronicDeth/intellij-elixir#credo) - Elixir plugin for JetBrains IDEs (IntelliJ IDEA, Rubymine, PHPStorm, PyCharm, etc)
* [linter-elixir-credo](https://atom.io/packages/linter-elixir-credo) - Package for Atom editor (by @smeevil)
* [Elixir Linter (Credo)](https://marketplace.visualstudio.com/items?itemName=pantajoe.vscode-elixir-credo) - VSCode extension (by @pantajoe)
* [flycheck](https://www.flycheck.org/en/latest/languages.html#elixir) - Emacs syntax checking extension

### Automated Code Review

* [Codacy](https://www.codacy.com/) - checks your code from style to security, duplication, complexity, and also integrates with coverage.
* [SourceLevel](https://sourcelevel.io/) - tracks how your code changes over time and have this information accessible to your whole team.
* [Stickler CI](https://stickler-ci.com/) - checks your code for style and best practices across your entire stack.

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
