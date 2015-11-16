defmodule Credo.Mixfile do
  use Mix.Project

  def project do
    [
      app: :credo,
      version: "0.1.0",
      elixir: "~> 1.0",
      escript: [main_module: Credo.CLI],
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps,
      test_coverage: [tool: Coverex.Task]
    ]
  end

  def application do
    [mod: {Credo, []}, applications: [:bunt, :logger]]
  end

  defp deps do
    [
      {:bunt, "~> 0.1.4"},
      {:coverex, "~> 1.4.1", only: :test}
    ]
  end
end
