defmodule Credo.Watcher do
  alias Credo.CLI.Output.UI

  @default_watch_path "."

  def run(argv) do
    spawn(fn ->
      path = get_path(argv)

      UI.puts([
        :bright,
        :magenta,
        "watch: ",
        :reset,
        :faint,
        "Now watching for changes in '#{path}' ...\n"
      ])

      start_watcher_process(path)

      watch_loop(argv, nil)
    end)
  end

  defp start_watcher_process(path) do
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

            file_that_changed = Path.relative_to_cwd(relative_path)

            Credo.run(exec_from_last_run || argv, [file_that_changed])
          else
            # data = inspect({System.os_time(:milliseconds), events, relative_path})
            # UI.puts([:bright, :magenta, "changes: ", :reset, :faint, data])
            exec_from_last_run
          end

        watch_loop(argv, exec)
    end
  end

  defp get_path([]), do: @default_watch_path

  defp get_path(argv) do
    {_options, argv_rest, _errors} = OptionParser.parse(argv, strict: [watch: :boolean])

    path = Enum.find(argv_rest, fn path -> File.exists?(path) or path =~ ~r/[\?\*]/ end)

    path || @default_watch_path
  end
end
