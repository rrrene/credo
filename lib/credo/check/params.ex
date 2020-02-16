defmodule Credo.Check.Params do
  @moduledoc """
  This module provides functions for handling parameters ("params") given to
  checks through `.credo.exs` (i.e. the `Credo.ConfigFile`).
  """

  @doc """
  Returns the given `field`'s `params` value.

  Example:

      defmodule SamepleCheck do
        def param_defaults do
          [foo: "bar"]
        end
      end

      iex> Credo.Check.Params.get([], :foo, SamepleCheck)
      "bar"
      iex> Credo.Check.Params.get([foo: "baz"], :foo, SamepleCheck)
      "baz"
  """
  def get(params, field, check_mod)

  # this one is deprecated
  def get(params, field, keywords) when is_list(keywords) do
    case params[field] do
      nil ->
        keywords[field]

      val ->
        val
    end
  end

  def get(params, field, check_mod) do
    case params[field] do
      nil ->
        check_mod.param_defaults[field]

      val ->
        val
    end
  end
end
