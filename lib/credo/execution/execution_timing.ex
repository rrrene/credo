defmodule Credo.Execution.ExecutionTiming do
  @moduledoc """
  The `ExecutionTiming` module can help in timing the execution of code parts and
  storing those timing inside the `Credo.Execution` struct.
  """

  use GenServer

  alias Credo.Execution

  @doc """
  Runs the given `fun` and prints the time it took with the given `label`.

      iex> Credo.Execution.ExecutionTiming.inspect("foo", fn -> some_complicated_stuff() end)
      foo: 51284

  """
  def inspect(label, fun) do
    {duration, result} = :timer.tc(fun)

    # credo:disable-for-lines:3 Credo.Check.Warning.IoInspect
    duration
    |> format_time()
    |> IO.inspect(label: label)

    result
  end

  @doc """
  Returns the current timestamp in the same format (microseconds) as the returned starting times of `run/1`.
  """
  def now(), do: :os.system_time(:microsecond)

  @doc """
  Runs the given `fun` and returns a tuple of `{started_at, duration, result}`.

      iex> Credo.Execution.ExecutionTiming.run(fn -> some_complicated_stuff() end)
      {1540540119448181, 51284, [:whatever, :fun, :returned]}

  """
  def run(fun) do
    started_at = now()
    {duration, result} = :timer.tc(fun)

    {started_at, duration, result}
  end

  @doc "Same as `run/1` but takes `fun` and `args` separately."
  def run(fun, args) do
    started_at = now()
    {duration, result} = :timer.tc(fun, args)

    {started_at, duration, result}
  end

  @doc """
  Adds a timing to the given `exec` using the given values of `tags`, `started_at` and `duration`.
  """
  def append(%Execution{timing_pid: pid}, tags, started_at, duration) do
    spawn(fn ->
      GenServer.call(pid, {:append, tags, started_at, duration})
    end)
  end

  @doc """
  Adds a timing piped from `run/2` to the given `exec` (using the given values of `tags`, `started_at` and `duration`).
  """
  def append({started_at, duration, _result}, %Execution{timing_pid: pid}, tags) do
    spawn(fn ->
      GenServer.call(pid, {:append, tags, started_at, duration})
    end)
  end

  @doc """
  Returns all timings for the given `exec`.
  """
  def all(%Execution{timing_pid: pid}) do
    GenServer.call(pid, :all)
  end

  @doc """
  Groups all timings for the given `exec` and `tag_name`.
  """
  def grouped_by_tag(exec, tag_name) do
    map =
      exec
      |> all()
      |> Enum.filter(fn {tags, _started_at, _time} -> tags[tag_name] end)
      |> Enum.group_by(fn {tags, _started_at, _time} -> tags[tag_name] end)

    map
    |> Map.keys()
    |> Enum.map(fn map_key ->
      sum = Enum.reduce(map[map_key], 0, fn {_tags, _, time}, acc -> time + acc end)

      {[{tag_name, map_key}, {:accumulated, true}], nil, sum}
    end)
  end

  @doc """
  Returns all timings for the given `exec` and `tag_name`.
  """
  def by_tag(exec, tag_name) do
    exec
    |> all()
    |> Enum.filter(fn {tags, _started_at, _time} -> tags[tag_name] end)
  end

  @doc """
  Returns all timings for the given `exec` and `tag_name` where the tag's value also matches the given `regex`.
  """
  def by_tag(exec, tag_name, regex) do
    exec
    |> all()
    |> Enum.filter(fn {tags, _started_at, _time} ->
      tags[tag_name] && to_string(tags[tag_name]) =~ regex
    end)
  end

  @doc """
  Returns the earliest timestamp for the given `exec`.
  """
  def started_at(exec) do
    {_, started_at, _} =
      exec
      |> all()
      |> List.first()

    started_at
  end

  @doc """
  Returns the latest timestamp plus its duration for the given `exec`.
  """
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

  @doc false
  def start_server(exec) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [])

    %Execution{exec | timing_pid: pid}
  end

  @doc false
  def init(_) do
    {:ok, []}
  end

  @doc false
  def handle_call({:append, tags, started_at, time}, _from, current_state) do
    new_current_state = [{tags, started_at, time} | current_state]

    {:reply, :ok, new_current_state}
  end

  @doc false
  def handle_call(:all, _from, current_state) do
    list = Enum.sort_by(current_state, fn {_, started_at, _} -> started_at end)

    {:reply, list, current_state}
  end
end
