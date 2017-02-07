defmodule Credo.Service.Commands do
  use GenServer

  @command_map %{
    "categories" => Credo.CLI.Command.Categories,
    "explain" => Credo.CLI.Command.Explain,
    "gen.check" => Credo.CLI.Command.GenCheck,
    "gen.config" => Credo.CLI.Command.GenConfig,
    "help" => Credo.CLI.Command.Help,
    "list" => Credo.CLI.Command.List,
    "suggest" => Credo.CLI.Command.Suggest,
    "version" => Credo.CLI.Command.Version,
  }

  def start_link(opts \\ []) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def get(command_name) do
    GenServer.call(__MODULE__, {:get, command_name})
  end

  def modules do
    GenServer.call(__MODULE__, {:modules})
  end

  @doc "Returns a List with the names of all commands."
  def names do
    GenServer.call(__MODULE__, {:names})
  end

  @doc "Returns a List of all command modules."
  def put(command_name, command_mod) do
    GenServer.call(__MODULE__, {:put, command_name, command_mod})
  end

  # callbacks
  def init(_) do
    {:ok, @command_map}
  end

  def handle_call({:get, command_name}, _from, current_state) do
    {:reply, current_state[command_name], current_state}
  end

  def handle_call({:put, command_name, command_mod}, _from, current_state) do
    {:reply, command_mod, Map.put(current_state, command_name, command_mod)}
  end

  def handle_call({:modules}, _from, current_state) do
    {:reply, Map.values(current_state), current_state}
  end

  def handle_call({:names}, _from, current_state) do
    names =
      current_state
      |> Map.keys()
      |> Enum.map(&to_string/1)

    {:reply, names, current_state}
  end
end
