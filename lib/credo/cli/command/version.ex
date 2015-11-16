defmodule Credo.CLI.Command.Version do
  def run(_, _) do
    Credo.version
    |> IO.puts
  end
end
