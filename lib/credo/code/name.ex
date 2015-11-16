defmodule Credo.Code.Name do
  @moduledoc """
  This module provides helper functions to process names of functions, module
  attributes and modules.
  """

  def last(name) do
    name |> to_string |> String.split(".") |> List.last
  end

  def pascal_case?(name) do
    name |> String.match?(~r/^[A-Z][a-zA-Z0-9]*$/)
  end

  def split_pascal_case(name) do
    name |> String.replace(~r/([A-Z])/, " \\1") |> String.split
  end

  def snake_case?(name) do
    name |> String.match?(~r/^[a-z0-9\_\?\!]+$/)
  end
end
