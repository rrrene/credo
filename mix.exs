defmodule Credo.Mixfile do
  use Mix.Project

  @version "1.3.1"

  def project do
    [
      app: :credo,
      version: @version,
      elixir: ">= 1.5.0",
      escript: [main_module: Credo.CLI],
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [tool: Coverex.Task],
      name: "Credo",
      description: "A static code analysis tool with a focus on code consistency and teaching.",
      package: package(),
      source_url: "https://github.com/rrrene/credo",
      # The main page in the docs
      docs: docs()
    ]
  end

  defp docs do
    [
      source_ref: "v#{@version}",
      main: "overview",
      logo: "assets/logo.png",
      extra_section: "GUIDES",
      assets: "guides/assets",
      formatters: ["html"],
      groups_for_modules: groups_for_modules(),
      extras: extras(),
      groups_for_extras: groups_for_extras()
    ]
  end

  defp extras do
    [
      "guides/introduction/overview.md",
      "guides/introduction/installation.md",
      "guides/introduction/basic_usage.md",
      "guides/introduction/exit_statuses.md",
      "guides/introduction/mix_tasks.md",

      # Plugins

      "guides/custom_checks/adding_checks.md",
      "guides/custom_checks/testing.md",

      # Configuration

      "guides/configuration/config_file.md",
      "guides/configuration/cli_switches.md",
      "guides/configuration/config_comments.md",

      # Plugins

      "guides/plugins/plugins.md"
    ]
  end

  defp groups_for_extras do
    [
      Introduction: ~r/guides\/introduction\/.?/,
      Configuration: ~r/guides\/configuration\//,
      "Custom Checks": ~r/guides\/custom_checks\//,
      Plugins: ~r/guides\/plugins\//
    ]
  end

  defp groups_for_modules do
    # Ungrouped Modules:

    []
  end

  defp package do
    [
      files: [
        ".credo.exs",
        ".template.check.ex",
        ".template.debug.html",
        "lib",
        "LICENSE",
        "mix.exs",
        "README.md"
      ],
      maintainers: ["René Föhring"],
      licenses: ["MIT"],
      links: %{
        "GitHub" => "https://github.com/rrrene/credo",
        "Changelog" => "https://github.com/rrrene/credo/blob/master/CHANGELOG.md"
      }
    ]
  end

  def application do
    [mod: {Credo.Application, []}, applications: [:bunt, :logger, :inets]]
  end

  defp deps do
    [
      {:bunt, "~> 0.2.0"},
      {:jason, "~> 1.0"},
      {:ex_doc, "~> 0.16", only: :dev, runtime: false},
      {:inch_ex, "~> 0.1", only: [:dev, :test], runtime: false}
    ]
  end
end
