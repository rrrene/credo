defmodule Credo.Service.SourceFiles do
  use GenServer

  alias Credo.SourceFile

  def start_link(opts \\ []) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def put(list) do
    GenServer.call(__MODULE__, {:put, list})
  end

  def get() do
    GenServer.call(__MODULE__, {:get})
  end

  # callbacks

  def init(_) do
    {:ok, []}
  end

  def handle_call({:put, new_state}, _from, current_state) do
    {:reply, new_state, new_state}
  end

  def handle_call({:get}, _from, current_state) do
    {:reply, current_state, current_state}
  end
end
