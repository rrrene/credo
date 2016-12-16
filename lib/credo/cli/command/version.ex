defmodule Credo.CLI.Command.Version do
  use Credo.CLI.Command

  alias Credo.CLI.Output.UI

  @doc false
  def run(_, _) do
    UI.puts Credo.version
    :ok
  end
end
