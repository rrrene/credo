defmodule Mix.Tasks.Credo do
  use Mix.Task

  @shortdoc  "Run code analysis (use `--help` for options)"
  @moduledoc @shortdoc

  @doc false
  def run(argv) do
    Credo.CLI.main(argv)
  end
end
