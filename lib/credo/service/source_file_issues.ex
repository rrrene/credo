defmodule Credo.Service.SourceFileIssues do
  use GenServer

  alias Credo.SourceFile

  def start_link(opts \\ []) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def to_map do
    GenServer.call(__MODULE__, {:to_map})
  end

  def append(%SourceFile{filename: filename}, issue) do
    GenServer.call(__MODULE__, {:append, filename, issue})
  end

  def get(%SourceFile{filename: filename}) do
    GenServer.call(__MODULE__, {:get, filename})
  end

  # callbacks

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:append, filename, issue}, _from, current_state) do
    issues = List.wrap(current_state[filename])
    new_issue_list = List.wrap(issue) ++ issues
    new_current_state = Map.put(current_state, filename, new_issue_list)

    {:reply, new_issue_list, new_current_state}
  end

  def handle_call({:get, filename}, _from, current_state) do
    {:reply, List.wrap(current_state[filename]), current_state}
  end

  def handle_call({:to_map}, _from, current_state) do
    {:reply, current_state, current_state}
  end
end
