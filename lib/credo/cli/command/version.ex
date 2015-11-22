defmodule Credo.CLI.Command.Version do
  use Credo.CLI.Command
  
  def run(_, _) do
    Credo.version
    |> IO.puts
  end
end
