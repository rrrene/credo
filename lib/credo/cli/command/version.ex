defmodule Credo.CLI.Command.Version do
  use Credo.CLI.Command

  alias Credo.CLI.Output.UI

  @doc false
  def run(exec) do
    UI.puts Credo.version

    exec
  end
end
