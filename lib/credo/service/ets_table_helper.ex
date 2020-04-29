defmodule Credo.Service.ETSTableHelper do
  @moduledoc false

  defmacro __using__(_opts \\ []) do
    quote do
      use GenServer

      @timeout 60_000

      alias Credo.Service.ETSTableHelper

      @table_name __MODULE__

      def start_link(opts \\ []) do
        {:ok, _pid} = GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      def get(source_file) do
        hash = source_file.hash

        case :ets.lookup(@table_name, hash) do
          [{^hash, value}] ->
            {:ok, value}

          [] ->
            :notfound
        end
      end

      def put(source_file, value) do
        GenServer.call(__MODULE__, {:put, source_file.hash, value}, @timeout)
      end

      # callbacks

      def init(opts), do: ETSTableHelper.init(@table_name, opts)

      def handle_call(msg, from, current_state),
        do: ETSTableHelper.handle_call(@table_name, msg, from, current_state)
    end
  end

  def init(table_name, _) do
    ets = :ets.new(table_name, [:named_table, read_concurrency: true])

    {:ok, ets}
  end

  def handle_call(table_name, {:put, hash, value}, _from, current_state) do
    :ets.insert(table_name, {hash, value})

    {:reply, value, current_state}
  end
end
