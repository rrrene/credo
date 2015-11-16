defmodule Credo.Service.SourceFileWithoutStringAndSigils do
  use GenServer

  def start_link(opts \\ []) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get(filename) do
    GenServer.call(__MODULE__, {:get, filename})
  end

  def put(filename, source) do
    GenServer.cast(__MODULE__, {:put, filename, source})
  end

  # callbacks

  def init(_) do
    {:ok, HashDict.new}
  end

  def handle_call({:get, filename}, _from, current_state) do
    if HashDict.has_key?(current_state, filename) do
      reply = HashDict.fetch(current_state, filename)
      {:reply, reply, current_state}
    else
      {:reply, :notfound, current_state}
    end
  end

  def handle_cast({:put, filename, source}, current_state) do
    if HashDict.has_key?(current_state, filename) do
      {:noreply, current_state}
    else
      {:noreply, HashDict.put(current_state, filename, source)}
    end
  end
end
