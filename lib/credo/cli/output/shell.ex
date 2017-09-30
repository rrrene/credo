defmodule Credo.CLI.Output.Shell do
  use GenServer

  def start_link(opts \\ []) do
    {:ok, _pid} = GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end

  def puts do
    puts("")
  end
  def puts(value) do
    GenServer.call(__MODULE__, {:puts, value})
  end

  def use_colors(use_colors) do
    GenServer.call(__MODULE__, {:use_colors, use_colors})
  end

  @doc "Like `puts`, but writes to `:stderr`."
  def warn(value) do
    GenServer.call(__MODULE__, {:warn, value})
  end

  # callbacks

  def init(_) do
    {:ok, %{use_colors: true}}
  end

  def handle_call({:use_colors, use_colors}, _from, current_state) do
    new_state = Map.put(current_state, :use_colors, use_colors)

    {:reply, nil, new_state}
  end

  def handle_call({:puts, value}, _from, %{use_colors: true} = current_state) do
    do_puts(value)

    {:reply, nil, current_state}
  end
  def handle_call({:puts, value}, _from, %{use_colors: false} = current_state) do
    value
    |> remove_colors()
    |> do_puts()

    {:reply, nil, current_state}
  end

  def handle_call({:warn, value}, _from, %{use_colors: true} = current_state) do
    do_warn(value)

    {:reply, nil, current_state}
  end
  def handle_call({:warn, value}, _from, %{use_colors: false} = current_state) do
    value
    |> remove_colors()
    |> do_warn()

    {:reply, nil, current_state}
  end

  defp remove_colors(value) do
    value
    |> List.wrap
    |> List.flatten
    |> Enum.reject(&is_atom/1)
  end

  defp do_puts(value) do
    Bunt.puts(value)
  end

  defp do_warn(value) do
    Bunt.warn(value)
  end
end
