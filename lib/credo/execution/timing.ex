defmodule Credo.Execution.Timing do
  use GenServer

  alias Credo.Execution

  def now(), do: :os.system_time()

  def run(fun) do
    started_at = now()
    {time, result} = :timer.tc(fun)

    {started_at, time, result}
  end

  def run(fun, args) do
    started_at = now()
    {time, result} = :timer.tc(fun, args)

    {started_at, time, result}
  end

  def append(%Execution{timing_pid: pid}, tags, started_at, duration) do
    GenServer.call(pid, {:append, tags, started_at, duration})
  end

  def all(%Execution{timing_pid: pid}) do
    GenServer.call(pid, :all)
  end

  def by_tag(exec, tag_name) do
    map =
      all(exec)
      |> Enum.filter(fn {tags, _started_at, _time} -> tags[tag_name] end)
      |> Enum.group_by(fn {tags, _started_at, _time} -> tags[tag_name] end)

    map
    |> Map.keys()
    |> Enum.map(fn map_key ->
      sum = Enum.reduce(map[map_key], 0, fn {_tags, _, time}, acc -> time + acc end)

      {[{tag_name, map_key}, {:accumulated, true}], nil, sum}
    end)
  end

  # callbacks

  def start_server(exec) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [])

    %Execution{exec | timing_pid: pid}
  end

  def init(_) do
    {:ok, []}
  end

  def handle_call({:append, tags, started_at, time}, _from, current_state) do
    new_current_state = current_state ++ [{tags, started_at, time}]

    {:reply, new_current_state, new_current_state}
  end

  def handle_call(:all, _from, current_state) do
    {:reply, current_state, current_state}
  end
end
