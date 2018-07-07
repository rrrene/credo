defmodule Credo.Execution.Timing do
  use GenServer

  alias Credo.Execution

  def inspect(label, fun) do
    {time, result} = :timer.tc(fun)

    time
    |> format_time()
    |> IO.inspect(label: label)

    result
  end

  def now(), do: :os.system_time(:microsecond)

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
    spawn(fn ->
      GenServer.call(pid, {:append, tags, started_at, duration})
    end)
  end

  def all(%Execution{timing_pid: pid}) do
    GenServer.call(pid, :all)
  end

  def grouped_by_tag(exec, tag_name) do
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

  def by_tag(exec, tag_name) do
    exec
    |> all()
    |> Enum.filter(fn {tags, _started_at, _time} -> tags[tag_name] end)
  end

  def by_tag(exec, tag_name, regex) do
    exec
    |> all()
    |> Enum.filter(fn {tags, _started_at, _time} ->
      tags[tag_name] && to_string(tags[tag_name]) =~ regex
    end)
  end

  def started_at(exec) do
    {_, started_at, _} =
      exec
      |> all()
      |> List.first()

    started_at
  end

  def ended_at(exec) do
    {_, started_at, duration} =
      exec
      |> all()
      |> List.last()

    started_at + duration
  end

  defp format_time(time) do
    cond do
      time > 1_000_000 ->
        "#{div(time, 1_000_000)}s"

      time > 1_000 ->
        "#{div(time, 1_000)}ms"

      true ->
        "#{time}μs"
    end
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
    new_current_state = [{tags, started_at, time} | current_state]

    {:reply, :ok, new_current_state}
  end

  def handle_call(:all, _from, current_state) do
    list = Enum.sort_by(current_state, fn {_, started_at, _} -> started_at end)

    {:reply, list, current_state}
  end
end
