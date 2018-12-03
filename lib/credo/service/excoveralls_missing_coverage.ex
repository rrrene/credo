defmodule Credo.Service.ExcoverallsMissingCoverage do
  @moduledoc """
  Supports lookup of missing lines of test coverage from the
  ExCoveralls JSON file, if it is present.

  Note that the map is sparse, meaning it only contains source
  lines which SHOULD have coverage, but DON'T.
  """

  use GenServer

  def start_link() do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    new_state =
      case slurp_coveralls_json() do
        {:ok, data} -> parse_coveralls_json(data)
        _ -> :no_data
      end

    {:ok, new_state}
  end

  def data_available?() do
    GenServer.call(__MODULE__, :has_data)
  end

  def coverage_map() do
    GenServer.call(__MODULE__, :coverage_map)
  end

  def handle_call(:has_data, _from, :no_data) do
    {:reply, false, :no_data}
  end

  def handle_call(:has_data, _from, state) do
    {:reply, true, state}
  end

  def handle_call(:coverage_map, _from, state) do
    {:reply, state, state}
  end

  defp slurp_coveralls_json() do
    case File.exists?("cover/excoveralls.json") do
      false -> :no_file
      _ -> read_coveralls_json()
    end
  end

  defp read_coveralls_json() do
    case File.read("cover/excoveralls.json") do
      {:ok, bin} -> Jason.decode(bin)
      e -> e
    end
  end

  defp parse_coveralls_json(structure) do
    case Map.fetch(structure, "source_files") do
      :error -> %{}
      {:ok, c_items} -> items_into_map(c_items)
    end
  end

  defp items_into_map(c_items) do
    Enum.reduce(c_items, %{}, fn c_item, acc ->
      case Map.fetch(c_item, "name") do
        :error ->
          acc

        {:ok, name} ->
          Map.put(
            acc,
            name,
            map_code_lines(c_item)
          )
      end
    end)
  end

  defp map_code_lines(c_item) do
    case Map.fetch(c_item, "coverage") do
      :error -> %{}
      {:ok, l} -> index_and_map_code_lines(l)
    end
  end

  defp index_and_map_code_lines(lines) do
    lines
    |> Enum.with_index()
    |> Enum.reduce(%{}, fn {e, idx}, acc ->
      case e do
        0 -> Map.put(acc, idx + 1, e)
        _ -> acc
      end
    end)
  end
end
