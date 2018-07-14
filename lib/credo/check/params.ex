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
  def get(params, field, default_params \\ []) when is_list(params) do
    case params[field] do
      nil ->
        default_params[field]

      val ->
        val
    end
  end
end
