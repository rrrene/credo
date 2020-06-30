defmodule Credo.Execution.ExecutionIssues do
  @moduledoc false

  use GenServer

  alias Credo.Execution
  alias Credo.Issue
  alias Credo.SourceFile

  def start_server(exec) do
    {:ok, pid} = GenServer.start_link(__MODULE__, [])

    %Execution{exec | issues_pid: pid}
  end

  @doc "Appends an `issue` for the specified `filename`."
  def append(%Execution{issues_pid: pid}, issues) when is_list(issues) do
    issues
    |> Enum.group_by(& &1.filename)
    |> Enum.each(fn {filename, issues} ->
      GenServer.call(pid, {:append, filename, issues})
    end)
  end

  def append(%Execution{issues_pid: pid}, %Issue{} = issue) do
    GenServer.call(pid, {:append, issue.filename, issue})
  end

  @doc "Appends an `issue` for the specified `filename`."
  def append(%Execution{issues_pid: pid}, %SourceFile{filename: filename}, issue) do
    GenServer.call(pid, {:append, filename, issue})
  end

  @doc "Returns the issues for the specified `filename`."
  def get(%Execution{issues_pid: pid}, %SourceFile{filename: filename}) do
    GenServer.call(pid, {:get, filename})
  end

  @doc "Sets/overwrites all `issues` for the given Execution struct."
  def set(%Execution{issues_pid: pid}, issues) do
    GenServer.call(pid, {:set, issues})
  end

  @doc "Returns all `issues` for the given Execution struct."
  def to_map(%Execution{issues_pid: pid}) do
    GenServer.call(pid, :to_map)
  end

  # callbacks

  def init(_) do
    {:ok, %{}}
  end

  def handle_call({:append, filename, issue_or_issue_list}, _from, current_state) do
    existing_issues = List.wrap(current_state[filename])
    new_issue_list = List.wrap(issue_or_issue_list) ++ existing_issues
    new_current_state = Map.put(current_state, filename, new_issue_list)

    {:reply, new_issue_list, new_current_state}
  end

  def handle_call({:get, filename}, _from, current_state) do
    {:reply, List.wrap(current_state[filename]), current_state}
  end

  def handle_call({:set, issues}, _from, _current_state) do
    new_current_state = Enum.group_by(issues, fn issue -> issue.filename end)

    {:reply, new_current_state, new_current_state}
  end

  def handle_call(:to_map, _from, current_state) do
    {:reply, current_state, current_state}
  end
end
