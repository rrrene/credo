defmodule Credo.CLI.Command.Version do
  @moduledoc false

  @shortdoc "Show Credo's version number"

  use Credo.CLI.Command

  alias Credo.CLI.Output.UI

  @doc false
  def call(exec, _opts) do
    UI.puts(Credo.version())

    exec
  end
end
