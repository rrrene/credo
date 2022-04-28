defmodule Mix.Tasks.Credo do
  use Mix.Task

  @shortdoc "Run code analysis (use `--help` for options)"
  @moduledoc @shortdoc

  # Load application config because some custom checks depend on configuration
  @requirements ["app.config"]

  @doc false
  def run(argv) do
    Credo.CLI.main(argv)
  end
end
