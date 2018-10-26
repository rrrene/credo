defmodule Credo.Service.Commands do
  @moduledoc """
  This module is used to keep track of the available commands.
  """

  use GenServer

  @command_map %{
    "categories" => Credo.CLI.Command.Categories.CategoriesCommand,
    "explain" => Credo.CLI.Command.Explain.ExplainCommand,
    "gen.check" => Credo.CLI.Command.GenCheck,
    "gen.config" => Credo.CLI.Command.GenConfig,
    "help" => Credo.CLI.Command.Help,
    "info" => Credo.CLI.Command.Info.InfoCommand,
    "list" => Credo.CLI.Command.List.ListCommand,
    "suggest" => Credo.CLI.Command.Suggest.SuggestCommand,
    "version" => Credo.CLI.Command.Version
  }

  @doc false
  def start_link(opts \\ []) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc """
  Returns the registered module for the given `command_name`.

      iex> Credo.Service.Commands.get("help")
      Credo.CLI.Command.Help

  """
  def get(command_name) do
    GenServer.call(__MODULE__, {:get, command_name})
  end

  @doc "Returns a List of all command modules."
  def modules do
    GenServer.call(__MODULE__, {:modules})
  end

  @doc "Returns a List with the names of all commands."
  def names do
    GenServer.call(__MODULE__, {:names})
  end

  @doc """
  Registers a given `command_mod` with the given `command_name`.

      iex> Credo.Service.Commands.put("help", Credo.CLI.Command.Help)

  """
  def put(command_name, command_mod) do
    GenServer.call(__MODULE__, {:put, command_name, command_mod})
  end

  # callbacks

  @doc false
  def init(_) do
    {:ok, @command_map}
  end

  @doc false
  def handle_call({:get, command_name}, _from, current_state) do
    {:reply, current_state[command_name], current_state}
  end

  @doc false
  def handle_call({:put, command_name, command_mod}, _from, current_state) do
    {:reply, command_mod, Map.put(current_state, command_name, command_mod)}
  end

  @doc false
  def handle_call({:modules}, _from, current_state) do
    {:reply, Map.values(current_state), current_state}
  end

  @doc false
  def handle_call({:names}, _from, current_state) do
    names =
      current_state
      |> Map.keys()
      |> Enum.map(&to_string/1)

    {:reply, names, current_state}
  end
end
