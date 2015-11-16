defmodule Mix.Tasks.Credo do
  use Mix.Task

  @shortdoc  "Run code analysis"
  @moduledoc @shortdoc

  def run(argv) do
    Credo.CLI.main(argv)
  end
end
