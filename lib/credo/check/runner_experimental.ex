defmodule Credo.Check.RunnerExperimental do
  @moduledoc false

  # This module is responsible for running checks based on the context represented
  # by the current `Credo.Execution`.

  alias Credo.CLI.Output.UI
  alias Credo.Execution

  @doc """
  Runs all checks on all source files (according to the config).
  """
  def run(source_files, exec) when is_list(source_files) do
    check_tuples =
      exec
      |> Execution.checks()
      |> warn_about_ineffective_patterns(exec)
      |> fix_old_notation_for_checks_without_params()

    {:ok, server_pid} = GenServer.start_link(__MODULE__.Server, check_tuples)

    runner_config = %{
      runner_pid: self(),
      server_pid: server_pid,
      max_concurrent_check_runs: :erlang.system_info(:logical_processors_available)
    }

    do_run(runner_config, exec, 0)

    :ok
  end

  defp do_run(runner_config, exec, taken) do
    available = runner_config.max_concurrent_check_runs - taken

    # IO.puts("\ndo_run")

    cond do
      available <= 0 ->
        # IO.puts("1")
        wait_for_check_finished(runner_config, exec, taken)

      modules = __MODULE__.Server.take_check_tuples(runner_config.server_pid, available) ->
        spawn_run_checks(runner_config, exec, modules, taken)

      # we fall thru here if there are no checks left
      # there are two options: we are done ...
      taken == 0 ->
        :ok

      # ... or we need for the very last batch to finish up
      true ->
        wait_for_check_finished(runner_config, exec, taken)
    end
  end

  defp wait_for_check_finished(runner_config, exec, taken) do
    receive do
      {_spawned_pid, {:check_finished, _check}} ->
        # IO.puts("Finished #{check}")
        do_run(runner_config, exec, taken - 1)
    end
  end

  defp spawn_run_checks(runner_config, exec, [], taken) do
    do_run(runner_config, exec, taken)
  end

  defp spawn_run_checks(runner_config, exec, [check_tuple | rest], taken) do
    _spawned_pid = spawn_link(fn -> run_check(runner_config, exec, check_tuple) end)
    spawn_run_checks(runner_config, exec, rest, taken + 1)
  end

  defp run_check(runner_config, exec, {check, params}) do
    source_files = Credo.Execution.get_source_files(exec)

    try do
      check.run_on_all_source_files(exec, source_files, params)
    rescue
      error ->
        warn_about_failed_run(check, source_files)

        if exec.crash_on_error do
          reraise error, System.stacktrace()
        else
          []
        end
    end

    send(runner_config.runner_pid, {self(), {:check_finished, check}})
  end

  defp warn_about_failed_run(check, %Credo.SourceFile{} = source_file) do
    UI.warn("Error while running #{check} on #{source_file.filename}")
  end

  defp warn_about_failed_run(check, _) do
    UI.warn("Error while running #{check}")
  end

  defp fix_old_notation_for_checks_without_params(checks) do
    Enum.map(checks, fn
      {check} -> {check, []}
      {check, params} -> {check, params}
    end)
  end

  defp warn_about_ineffective_patterns(
         {checks, _included_checks, []},
         %Execution{ignore_checks: [_ | _] = ignore_checks}
       ) do
    UI.warn([
      :red,
      "A pattern was given to ignore checks, but it did not match any: ",
      inspect(ignore_checks)
    ])

    checks
  end

  defp warn_about_ineffective_patterns({checks, _, _}, _) do
    checks
  end

  defmodule Server do
    @moduledoc false
    @timeout :infinity

    use GenServer

    def take_check_tuples(pid, count) do
      GenServer.call(pid, {:take_check_tuples, count}, @timeout)
    end

    #
    # Server
    #

    @impl true
    def init(check_tuples) do
      state = %{
        waiting: nil,
        check_tuples: check_tuples
      }

      {:ok, state}
    end

    @impl true
    def handle_call({:take_check_tuples, count}, from, %{waiting: nil} = state) do
      {:noreply, take_check_tuples(%{state | waiting: {from, count}})}
    end

    defp take_check_tuples(%{waiting: nil} = state) do
      state
    end

    defp take_check_tuples(%{waiting: {from, _count}, check_tuples: []} = state) do
      GenServer.reply(from, nil)

      %{state | waiting: nil}
    end

    defp take_check_tuples(%{check_tuples: []} = state) do
      state
    end

    defp take_check_tuples(%{waiting: {from, count}, check_tuples: check_tuples} = state) do
      {reply, check_tuples} = Enum.split(check_tuples, count)

      GenServer.reply(from, reply)

      %{state | check_tuples: check_tuples, waiting: nil}
    end
  end
end
