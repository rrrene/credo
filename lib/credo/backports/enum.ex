defmodule Credo.Backports.Enum do
  @moduledoc """
  This module provides Enum functions which are not supported in all Elixir
  versions supported by Credo.
  """

  @doc """
  Splits the enumerable in two lists according to the given function fun.

      iex> Credo.Backports.Enum.split_with([true, false, true, true, false], &(&1))
      {[true, true, true], [false, false]}

      iex> Credo.Backports.Enum.split_with(["hello", "same", "sample"], &(String.starts_with?(&1, "he")))
      {["hello"], ["same", "sample"]}

  """
  def split_with(list, fun)

  if Version.match?(System.version, "< 1.6.0") do
    def split_with(list, fun), do: Enum.partition(list, fun)
  else
    def split_with(list, fun), do: Enum.split_with(list, fun)
  end
end
