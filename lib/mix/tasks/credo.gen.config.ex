defmodule Mix.Tasks.Credo.Gen.Config do
  use Mix.Task

  @shortdoc "Generate a new config for Credo"
  @moduledoc @shortdoc

  @doc false
  def run(argv) do
    Credo.CLI.main(["gen.config"] ++ argv)
  end
end
