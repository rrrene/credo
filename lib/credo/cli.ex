defmodule Credo.CLI do
  @moduledoc """
  `Credo.CLI` is the entrypoint for both the Mix task and the escript.
  """

  alias Credo.CLI.Output.UI
  alias Credo.Execution
  alias Credo.Execution.Task.WriteDebugReport

  @doc """
  Runs Credo with the given `argv` and exits the process.

  See `run/1` if you want to run Credo programmatically.
  """
  def main(argv \\ []) do
    Credo.Application.start(nil, nil)

    {options, _, _} = OptionParser.parse(argv, strict: [watch: :boolean])

    if options[:watch] do
      UI.puts([:bright, :magenta, "watch: ", :reset, :faint, "Now watching for changes ...\n"])

      argv
      |> get_path()
      |> start_watcher()

      watch_loop(argv, nil)
    else
      argv
      |> run()
      |> halt_if_exit_status_assigned()
    end
  end

  @doc """
  Runs Credo with the given `argv` and returns its final `Credo.Execution` struct.

  Example:

      iex> exec = Credo.CLI.run(["--only", "Readability"])
      iex> issues = Credo.Execution.get_issues(exec)
      iex> Enum.count(issues) > 0
      true

  """
  def run(argv) do
    argv
    |> Execution.build()
    |> Execution.run()
    |> WriteDebugReport.call([])
  end

  defp start_watcher(path) do
    {:ok, pid} = FileSystem.start_link(dirs: [path])
    FileSystem.subscribe(pid)
  end

  defp watch_loop(argv, exec_from_last_run) do
    receive do
      {:file_event, _worker_pid, {file_path, events}} ->
        elixir_file? = file_path =~ ~r/\.exs?$/
        in_ignored_directory? = file_path =~ ~r/\/deps\/$/
        relative_path = Path.relative_to_cwd(file_path)

        exec =
          if Enum.member?(events, :closed) && elixir_file? && !in_ignored_directory? do
            UI.puts([:bright, :magenta, "watch: ", :reset, :faint, relative_path, "\n"])

            run(argv)
          else
            UI.puts([
              :bright,
              :magenta,
              "changes: ",
              :reset,
              :faint,
              inspect({System.os_time(:milliseconds), events, relative_path})
            ])
          end

        watch_loop(argv, exec || exec_from_last_run)
    end
  end

  defp get_path(_argv), do: "."

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
