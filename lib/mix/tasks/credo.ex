defmodule Mix.Tasks.Credo do
  use Mix.Task

  @shortdoc  "Run code analysis (use `--help` for options)"
  @moduledoc @shortdoc

  @doc false
  def run(argv) do
    Credo.start nil, nil

    Credo.CLI.run(argv)
  end
end
