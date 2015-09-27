defmodule Mix.Tasks.Credo do
  use Mix.Task

  @shortdoc  "Statically analyse Elixir source files"
  @moduledoc @shortdoc

  def run(argv) do
    Credo.CLI.main(argv)
  end
end
