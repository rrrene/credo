defmodule Credo.Mixfile do
  use Mix.Project

  def project do
    [
      app: :credo,
      version: "0.0.1-dev",
      elixir: "~> 1.0",
      escript: [main_module: Credo.CLI],
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps
    ]
  end

  def application do
    [applications: [:logger]]
  end

  defp deps do
    [
      {:poison, "~> 1.2"},
      {:dogma, "~> 0.0.7"}
    ]
  end
end
