defmodule Credo.Check.Params do
  @moduledoc """
  This module provides functions for handling parameters ("params") given to
  checks through `.credo.exs` (i.e. the `Credo.ConfigFile`).
  """

  @doc """
  Returns the given `field`'s `params` value.

  Example:

      iex> Credo.Check.Params.get([], :foo, [foo: "bar"])
      "bar"
      iex> Credo.Check.Params.get([foo: "baz"], :foo, [foo: "bar"])
      "baz"
  """
  def get(params, field, check_mod) do
    case params[field] do
      nil ->
        check_mod.param_defaults[field]

      val ->
        val
    end
  end
end
