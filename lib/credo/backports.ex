defmodule Credo.Backports do
  defmodule Enum do
    if Version.match?(System.version(), ">= 1.12.0-rc") do
      def slice(a, x..y) do
        Elixir.Enum.slice(a, x..y//1)
      end
    end

    def slice(a, b) do
      Elixir.Enum.slice(a, b)
    end
  end

  defmodule String do
    if Version.match?(System.version(), ">= 1.12.0-rc") do
      def slice(a, x..y) do
        Elixir.String.slice(a, x..y//1)
      end
    end

    def slice(a, b) do
      Elixir.String.slice(a, b)
    end
  end
end
