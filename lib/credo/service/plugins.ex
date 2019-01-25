defmodule Credo.Service.Plugins do
  @moduledoc """
  This module is used to keep track of the available plugins.
  """

  use GenServer

  @doc false
  def start_link(opts \\ []) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @doc "Returns a List of all plugin modules."
  def modules do
    GenServer.call(__MODULE__, {:modules})
  end

  def put(plugin_mod) do
    GenServer.call(__MODULE__, {:put, plugin_mod})
  end

  # callbacks

  @doc false
  def init(_) do
    {:ok, []}
  end

  @doc false
  def handle_call({:put, plugin_mod}, _from, current_state) do
    {:reply, plugin_mod, current_state ++ [plugin_mod]}
  end

  @doc false
  def handle_call({:modules}, _from, current_state) do
    {:reply, current_state, current_state}
  end
end
