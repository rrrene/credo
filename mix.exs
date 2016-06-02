defmodule Credo.Mixfile do
  use Mix.Project

  def project do
    [
      app: :credo,
      version: "0.4.0-beta4",
      elixir: "~> 1.1",
      escript: [main_module: Credo.CLI],
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      test_coverage: [tool: Coverex.Task],
      name: "Credo",
      description: "A static code analysis tool for the Elixir language with a focus on code consistency and teaching.",
      package: package
    ]
  end

  defp package do
    [
      files: [".credo.exs", ".template.check.ex", "lib", "mix.exs",
              "README.md", "LICENSE"],
      maintainers: ["René Föhring"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/rrrene/credo"},
    ]
  end

  def application do
    [mod: {Credo, []}, applications: [:bunt, :logger]]
  end

  defp deps do
    [
      {:bunt, "~> 0.1.6"},
      {:inch_ex, "~> 0.4", only: [:dev, :test]},
      {:coverex, "~> 1.4.1", only: :test}
    ]
  end
end
