defmodule Credo.Execution.Task.ResolveConfig do
  use Credo.Execution.Task

  alias Credo.Sources
  alias Credo.CLI.Output.UI

  def call(exec, _opts) do
    exec
    |> UI.use_colors
    |> Credo.CheckForUpdates.run
    |> require_requires()
  end

  # Requires the additional files specified in the exec.
  defp require_requires(%Execution{requires: requires} = exec) do
    requires
    |> Sources.find
    |> Enum.each(&Code.require_file/1)

    exec
  end
end
