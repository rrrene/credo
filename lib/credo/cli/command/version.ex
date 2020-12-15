defmodule Credo.CLI.Command.Version do
  @moduledoc false

  alias Credo.CLI.Output.Formatter.JSON
  alias Credo.CLI.Output.UI
  alias Credo.CLI.Switch
  alias Credo.Execution

  use Credo.CLI.Command,
    short_description: "Show Credo's version number",
    cli_switches: [
      Switch.string("format"),
      Switch.boolean("version", alias: :v)
    ]

  @doc false
  def call(%Execution{format: "json"} = exec, _opts) do
    JSON.print_map(%{version: Credo.version()})

    exec
  end

  def call(exec, _opts) do
    UI.puts(Credo.version())

    exec
  end
end
