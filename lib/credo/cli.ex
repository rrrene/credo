defmodule Credo.CLI do
  @moduledoc """
  `Credo.CLI` is the entrypoint for both the Mix task and the escript.
  """

  alias Credo.Execution

  @doc """
  Runs Credo with the given `argv` and exits the process.

  See `Credo.run/1` if you want to run Credo programmatically.
  """
  def main(argv \\ []) do
    Credo.Application.start(nil, nil)

    {options, argv_rest, _errors} = OptionParser.parse(argv, strict: [watch: :boolean])

    if options[:watch] do
      Credo.Watcher.run(argv)

      receive do
        _ -> nil
      end
    else
      argv
      |> Credo.run()
      |> halt_if_exit_status_assigned()
    end
  end

  defp halt_if_exit_status_assigned(%Execution{mute_exit_status: true}) do
    # Skip if exit status is muted
  end

  defp halt_if_exit_status_assigned(exec) do
    exec
    |> Execution.get_assign("credo.exit_status", 0)
    |> halt_if_failed()
  end

  defp halt_if_failed(0), do: nil
  defp halt_if_failed(exit_status), do: exit({:shutdown, exit_status})
end
