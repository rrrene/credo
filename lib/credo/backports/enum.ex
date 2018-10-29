defmodule Credo.Backports.Enum do
  @moduledoc """
  This module provides functions from the `Enum` module which are not supported
  in all Elixir versions supported by Credo.
  """

  @doc """
  Splits the enumerable in two lists according to the given function fun.

      iex> Credo.Backports.Enum.split_with([true, false, true, true, false], &(&1))
      {[true, true, true], [false, false]}

      iex> Credo.Backports.Enum.split_with(["hello", "same", "sample"], &(String.starts_with?(&1, "he")))
      {["hello"], ["same", "sample"]}

  """
  def split_with(list, fun)

  if Version.match?(System.version(), ">= 1.6.0-rc") do
    def split_with(list, fun), do: Enum.split_with(list, fun)
  else
    def split_with(list, fun), do: Enum.partition(list, fun)
  end

  @doc """
  Splits the enumerable in two lists according to the given function fun.

      iex> Credo.Backports.Enum.chunk_every([1, 2, 3, 4, 5, 6], 2, 1)
      [[1, 2], [2, 3], [3, 4], [4, 5], [5, 6], [6]]

  """
  def chunk_every(list, count, step)

  if Version.match?(System.version(), ">= 1.5.0-rc") do
    def chunk_every(list, count, step), do: Enum.chunk_every(list, count, step)
  else
    def chunk_every(list, count, step), do: Enum.chunk(list, count, step, [])
  end
end
