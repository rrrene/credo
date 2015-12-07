defmodule Credo.CLI.Command.Version do
  use Credo.CLI.Command

  def run(_, _) do
    IO.puts Credo.version
    :ok
  end
end
