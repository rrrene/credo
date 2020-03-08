defmodule Credo.Check.Worker do
  @moduledoc false

  @doc """
  Runs all members of `workloads` using ``.
  """
  def run(workloads, max_concurrency, work_fn) do
    {:ok, server_pid} = GenServer.start_link(__MODULE__.Server, workloads)

    worker_context = %{
      runner_pid: self(),
      server_pid: server_pid,
      max_concurrency: max_concurrency,
      work_fn: work_fn,
      results: []
    }

    outer_loop(worker_context, 0)
  end

  @doc """
  Called when a workload has finished.
  """
  def send_workload_finished_to_runner(worker_context, _workload, result) do
    send(worker_context.runner_pid, {self(), {:workload_finished, result}})
  end

  defp outer_loop(worker_context, taken) do
    available = worker_context.max_concurrency - taken

    cond do
      available <= 0 ->
        wait_for_workload_finished(worker_context, taken)

      taken_workloads = __MODULE__.Server.take_workloads(worker_context.server_pid, available) ->
        inner_loop(worker_context, taken_workloads, taken)

      # we fall thru here if there are no checks left
      # there are two options: we are done ...
      taken == 0 ->
        {:ok, worker_context.results}

      # ... or we need for the very last batch to finish up
      true ->
        wait_for_workload_finished(worker_context, taken)
    end
  end

  defp wait_for_workload_finished(worker_context, taken) do
    receive do
      {_spawned_pid, {:workload_finished, result}} ->
        # IO.puts("Finished #{workload}")
        new_worker_context = %{worker_context | results: [result | worker_context.results]}

        outer_loop(new_worker_context, taken - 1)
    end
  end

  defp inner_loop(worker_context, [], taken) do
    outer_loop(worker_context, taken)
  end

  defp inner_loop(worker_context, [workload | rest], taken) do
    spawn_fn = fn ->
      result = worker_context.work_fn.(workload)

      send_workload_finished_to_runner(worker_context, workload, result)
    end

    spawn_link(spawn_fn)

    inner_loop(worker_context, rest, taken + 1)
  end

  defmodule Server do
    @moduledoc false
    @timeout :infinity

    use GenServer

    def take_workloads(pid, count) do
      GenServer.call(pid, {:take_workloads, count}, @timeout)
    end

    #
    # Server
    #

    @impl true
    def init(workloads) do
      state = %{
        waiting: nil,
        workloads: workloads
      }

      {:ok, state}
    end

    @impl true
    def handle_call({:take_workloads, count}, from, %{waiting: nil} = state) do
      {:noreply, take_workloads(%{state | waiting: {from, count}})}
    end

    defp take_workloads(%{waiting: nil} = state) do
      state
    end

    defp take_workloads(%{waiting: {from, _count}, workloads: []} = state) do
      GenServer.reply(from, nil)

      %{state | waiting: nil}
    end

    defp take_workloads(%{workloads: []} = state) do
      state
    end

    defp take_workloads(%{waiting: {from, count}, workloads: workloads} = state) do
      {reply, workloads} = Enum.split(workloads, count)

      GenServer.reply(from, reply)

      %{state | workloads: workloads, waiting: nil}
    end
  end
end
