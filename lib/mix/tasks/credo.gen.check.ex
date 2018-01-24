defmodule Mix.Tasks.Credo.Gen.Check do
  use Mix.Task

  @shortdoc "Generate a new custom check for Credo"
  @moduledoc @shortdoc

  @doc false
  def run(argv) do
    Credo.CLI.main(["gen.check"] ++ argv)
  end
end
