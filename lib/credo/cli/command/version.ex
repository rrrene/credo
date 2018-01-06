defmodule Credo.CLI.Command.Version do
  use Credo.CLI.Command

  alias Credo.CLI.Output.UI

  @shortdoc "Show Credo's version number"
  @moduledoc @shortdoc

  @doc false
  def call(exec, _opts) do
    UI.puts(Credo.version())

    exec
  end
end
