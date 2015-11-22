defmodule Credo.CLI.Command.Version do
  @shortdoc "Display the current file version"

  def run(_, _) do
    Credo.version
    |> IO.puts
  end
end
