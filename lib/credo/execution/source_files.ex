defmodule Credo.Execution.SourceFiles do
  use GenServer

  alias Credo.Execution

  def start_server(exec) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [])

    %Execution{exec | source_files_pid: pid}
  end

  def put(%Execution{source_files_pid: pid}, list) do
    GenServer.call(pid, {:put, list})
  end

  def get(%Execution{source_files_pid: pid}) do
    GenServer.call(pid, :get)
  end

  # callbacks

  def init(_) do
    {:ok, []}
  end

  def handle_call({:put, new_state}, _from, _current_state) do
    {:reply, new_state, new_state}
  end

  def handle_call(:get, _from, current_state) do
    {:reply, current_state, current_state}
  end
end
