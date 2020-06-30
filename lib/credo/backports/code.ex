defmodule Credo.Backports.Code do
  @moduledoc """
  This module provides functions from the `Code` module which are not supported
  in all Elixir versions supported by Credo.
  """

  @doc """
  Splits the enumerable in two lists according to the given function fun.

      iex> Credo.Backports.Code.ensure_compiled?(Credo.Check.Refactor.FunctionArity)
      true

      iex> Credo.Backports.Code.ensure_compiled?(Credo.Check.Foo)
      false

  """
  def ensure_compiled?(module)

  if Version.match?(System.version(), ">= 1.10.0-rc") do
    def ensure_compiled?(module) do
      case Code.ensure_compiled(module) do
        {:module, _} -> true
        {:error, _} -> false
      end
    end
  else
    def ensure_compiled?(module), do: Code.ensure_compiled?(module)
  end
end
