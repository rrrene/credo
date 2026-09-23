defmodule Credo.Service.ETSTableHelper do
  @moduledoc false

  # Provides a per-source-file cache backed by a public ETS table.
  #
  # The GenServer exists only to own the table (so it lives as long as the application).
  # Reads and writes go straight to ETS from the calling process, so that the many concurrent
  # check processes never serialize on a single process or copy values through its mailbox.
  #
  # This is safe since every cached value is a pure function of the key (the hash of the
  # source file's contents): concurrent writes of the same key write identical values,
  # so it doesn't matter which one wins.

  defmacro __using__(_opts \\ []) do
    quote do
      use GenServer

      alias Credo.Service.ETSTableHelper

      @table_name __MODULE__

      def start_link(opts \\ []) do
        {:ok, _pid} = GenServer.start_link(__MODULE__, opts, name: __MODULE__)
      end

      def get_or_compute(source_file, fallback_fun) when is_function(fallback_fun, 1) do
        case get(source_file) do
          {:ok, cached_value} ->
            cached_value

          :notfound ->
            computed_value = fallback_fun.(source_file)
            put(source_file, computed_value)
            computed_value
        end
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
        true = :ets.insert(@table_name, {source_file.hash, value})
        value
      end

      # callbacks

      def init(opts), do: ETSTableHelper.init(@table_name, opts)
    end
  end

  def init(table_name, _) do
    ets =
      :ets.new(table_name, [
        :named_table,
        :public,
        read_concurrency: true,
        write_concurrency: true
      ])

    {:ok, ets}
  end
end
